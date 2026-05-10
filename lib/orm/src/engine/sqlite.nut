local regex_members = regexp(@"\s+`(\w+)`\s+(\w+(?:\(\d+\))?)(.*)")
local regex_default_value = regexp(@"DEFAULT (?:'([^']*)'|(\S+))")

local regex_primary_keys = regexp(@"PRIMARY KEY\s*\((.*)\)")
local regex_primary_key_name = regexp(@"`(\S+?)`")

local regex_foreign_keys = regexp(@"FOREIGN KEY\s*\('(\w+)'\) REFERENCES '(\w+?)'\s*\('(\w+?)'\)((?:\s)ON (?:DELETE|UPDATE) (?:\w+))?((?:\s)ON (?:DELETE|UPDATE) (?:\w+))?")

local regex_integer_type = regexp(@"^(?:INT|INTEGER)$")

class ORM.SQLite
{
    _db = null

    static sq_to_sql_type = {
        "bool": "BOOLEAN",
        "integer": "INTEGER",
        "float": "REAL",
        "string": "TEXT"
    }

    static sql_to_sq_type = {
        "BOOLEAN": @(field_value) field_value != 0,
    }

    static sql_type_aliases = {
        "BOOL": "BOOLEAN",
    }

    static now_timestamp = ORM.Expression("CURRENT_TIMESTAMP")
    static now_date = ORM.Expression("(date('now'))")
    static now_time = ORM.Expression("(time('now'))")
    static now_unix = ORM.Expression("(strftime('%s','now'))")

    constructor(...)
    {
        _db = SQLite3.instance()
        vargv.insert(0, _db)
        SQLite3.constructor.acall(vargv)

        if (ORM.onSyncConnect)
            ORM.onSyncConnect(_db)

        execute(set_foreign_keys_constraint(true))
    }

    function execute(query)
    {
        return _db.execute(query)
    }

    function executeAsync(query, callback)
    {
        setTimer(callback, 1, 1, _db.execute(query))
    }

    function normalize_sql_type(type)
    {
        type = type.toupper()

        if (type in sql_type_aliases)
            return sql_type_aliases[type]

        return type
    }

    function is_integer_type(type)
    {
        return regex_integer_type.match(type.toupper())
    }

    function last_insert_id()
    {
        return "SELECT LAST_INSERT_ROWID() AS id;"
    }

    function getAutoIncrement(table_name)
    {
        local rows = ORM.engine.execute("SELECT seq FROM sqlite_sequence WHERE name = '" + table_name + "';")
        if (rows.len() > 0 && "seq" in rows[0] && rows[0]["seq"] != null)
            return rows[0]["seq"].tointeger()

        return 1
    }

    function setAutoIncrement(table_name, auto_increment_value)
    {
        ORM.engine.execute("UPDATE sqlite_sequence SET seq = " + (auto_increment_value) + " WHERE name = '" + table_name + "';")
    }

    function insert_default_values(table_name)
    {
        return "INSERT INTO `" + table_name + "` DEFAULT VALUES"
    }

    function on_duplicate_key_update()
    {
        return "ON CONFLICT DO UPDATE SET"
    }

    function get_foreign_keys_constraint()
    {
        return "PRAGMA foreign_keys;"
    }

    function create_table_options(class_attributes)
    {
        return ""
    }

    function set_foreign_keys_constraint(enabled)
    {
        return "PRAGMA foreign_keys = " + (enabled ? "ON;" : "OFF;")
    }

    function create_table_member(name, attribute, default_value)
    {
        local result = ""
        result += "\t`" + name + "` " + attribute.type
        result += ("not_null" in attribute && attribute.not_null ? " NOT NULL" : "")
        result += " DEFAULT " + default_value
        result += ("unique" in attribute && attribute.unique ? " UNIQUE" : "")

        return result
    }

    function create_table_primary_keys(class_data)
    {
        local result = ""

        if (class_data.auto_increment_column)
            result += "\tPRIMARY KEY(`" + class_data.auto_increment_column + "` AUTOINCREMENT)"
        else
        {
            result += "\tPRIMARY KEY("

            local i = 0, end = class_data.primary_keys.len()

            foreach (name in class_data.primary_keys)
            {
                result += "`" + name + "`"
                result += (++i != end) ? "," : ""
            }

            result += ")"
        }

        return result
    }

    function create_table_foreign_keys(class_data)
    {
        local result = ",\n"

        local i = 0, end = class_data.foreign_keys.len()

        foreach (name, foreign_key in class_data.foreign_keys)
        {
            result += "\tFOREIGN KEY('" + name + "') REFERENCES '" + foreign_key.table + "'('" + foreign_key.column +"')"

            if ("on_update" in foreign_key)
                result += " ON UPDATE " + foreign_key.on_update

            if ("on_delete" in foreign_key)
                result += " ON DELETE " + foreign_key.on_delete

            result += (++i != end) ? ",\n" : ""
        }

        return result
    }

    function get_foreign_key_policy_pair(foreign_key_policy)
    {
        local rule_name = "ON UPDATE "
        local idx = foreign_key_policy.find(rule_name)

        if (idx != null)
            return {name = "on_update", action = foreign_key_policy.slice(idx + rule_name.len())}

        rule_name = "ON DELETE "
        idx = foreign_key_policy.find(rule_name)

        if (idx != null)
            return {name = "on_delete", action = foreign_key_policy.slice(idx + rule_name.len())}

        throw "Unexpected foreign_key policy!"
    }

    function get_table_metadata(table_name)
    {
        local create_table_query = execute("SELECT * FROM sqlite_master WHERE type='table' AND name='" + table_name + "';")[0]["sql"]
        local result = {}
        local member_captures = regex_members.captureall(create_table_query)

        for (local i = 0, end = member_captures.len(); i < end; i += 4)
        {
            local name = create_table_query.slice(member_captures[i+1].begin, member_captures[i+1].end)
            local type = create_table_query.slice(member_captures[i+2].begin, member_captures[i+2].end)
            local properties = create_table_query.slice(member_captures[i+3].begin, member_captures[i+3].end)

            result[name] <- { type = normalize_sql_type(type) }

            if (properties.find("NOT NULL") != null)
                result[name].not_null <- true

            if (properties.find("UNIQUE") != null)
                result[name].unique <- true

            local default_captures = regex_default_value.captureall(properties)
            if (default_captures && default_captures.len() == 2)
            {
                local idx = (default_captures[0]) ? 0 : 1
                result[name].default_value <- properties.slice(default_captures[idx].begin, default_captures[idx].end)
            }
        }

        local primary_key_captures = regex_primary_keys.capture(create_table_query)
        if (primary_key_captures && primary_key_captures.len() >= 2)
        {
            local content = create_table_query.slice(primary_key_captures[1].begin, primary_key_captures[1].end)
            local name_captures = regex_primary_key_name.captureall(content)

            for(local i = 0, end = name_captures.len(); i < end; i += 2)
            {
                local capture = name_captures[i + 1]

                local name = content.slice(capture.begin, capture.end)
                result[name].primary_key <- true
            }

            if (content.find("AUTOINCREMENT") != null)
            {
                local name = content.slice(name_captures[1].begin, name_captures[1].end)
                result[name].auto_increment <- true
            }
        }

        local foreign_keys_captures = regex_foreign_keys.captureall(create_table_query)
        if (foreign_keys_captures && foreign_keys_captures.len() > 0)
        {
            for (local i = 0, end = foreign_keys_captures.len(); i < end; i += 6)
            {
                local name = create_table_query.slice(foreign_keys_captures[i+1].begin, foreign_keys_captures[i+1].end)
                local table = create_table_query.slice(foreign_keys_captures[i+2].begin, foreign_keys_captures[i+2].end)
                local column = create_table_query.slice(foreign_keys_captures[i+3].begin, foreign_keys_captures[i+3].end)

                result[name].foreign_key <- {
                    table = table
                    column = column
                }

                if (foreign_keys_captures[i + 4])
                {
                    local foreign_key_policy = create_table_query.slice(foreign_keys_captures[i + 4].begin, foreign_keys_captures[i + 4].end)
                    local foreign_key_pair = get_foreign_key_policy_pair(foreign_key_policy)

                    result[name].foreign_key[foreign_key_pair.name] <- foreign_key_pair.action
                }

                if (foreign_keys_captures[i + 5])
                {
                    local foreign_key_policy = create_table_query.slice(foreign_keys_captures[i + 5].begin, foreign_keys_captures[i + 5].end)
                    local foreign_key_pair = get_foreign_key_policy_pair(foreign_key_policy)

                    result[name].foreign_key[foreign_key_pair.name] <- foreign_key_pair.action
                }
            }
        }

        return result
    }
}
