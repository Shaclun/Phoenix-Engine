local regex_members = regexp(@"\s*`(\w+)`\s+(\w+(?:\(\d+\))?)(.*)")
local regex_default_value = regexp(@"DEFAULT (?:'([^']*)'|(\S+))")

local regex_primary_keys = regexp(@"PRIMARY KEY\s*\((.*)\)")
local regex_primary_key_name = regexp(@"`(\S+?)`")

local regex_unique_keys = regexp(@"UNIQUE KEY\s*`([^`]*)?`")
local regex_foreign_keys = regexp(@"FOREIGN KEY\s*\(`(\w+)`\) REFERENCES `(\w+?)`\s*\(`(\w+?)`\)((?:\s)ON (?:DELETE|UPDATE) (?:\w+))?((?:\s)ON (?:DELETE|UPDATE) (?:\w+))?")

local regex_integer_type = regexp(@"^(?:TINYINT|SMALLINT|MEDIUMINT|INT|INTEGER|BIGINT)(?:\(\d+\))?(?:\s+(?:UNSIGNED|ZEROFILL|UNSIGNED ZEROFILL))?$")

class ORM.MySQL
{
    _syncConnection = null
    _asyncConnection = null

    _queuedAsyncOperations = null

    static sq_to_sql_type = {
        "bool": "BOOLEAN",
        "integer": "INT(11)",
        "float": "FLOAT",
        "string": "VARCHAR(255)"
    }

    static sql_to_sq_type = {
        "BOOLEAN": @(field_value) field_value != 0,
    }

    static sql_type_aliases = {
        "INT": "INT(11)",
        "DEC": "DECIMAL",
        "BOOL": "BOOLEAN",
        "TINYINT(1)": "BOOLEAN",
    }

    static now_timestamp = ORM.Expression("CURRENT_TIMESTAMP")
    static now_date = ORM.Expression("(CURRENT_DATE)")
    static now_time = ORM.Expression("(CURRENT_TIME)")
    static now_unix = ORM.Expression("(UNIX_TIMESTAMP())")

    constructor(...)
    {
        _queuedAsyncOperations = []

        vargv.insert(0, this)
        _syncConnection = mysql_connect.acall(vargv)

        if (ORM.onSyncConnect)
            ORM.onSyncConnect(this._syncConnection)

        if (vargv.len() == 5)
            vargv.push(3306)

        if (vargv.len() == 6)
            vargv.push(null)

        vargv.push(function(conn)
        {
            _asyncConnection = conn

            if (ORM.onAsyncConnect)
                ORM.onAsyncConnect(conn)

            foreach (asyncOperation in _queuedAsyncOperations)
                this.executeAsync(asyncOperation.query, asyncOperation.callback)

            _queuedAsyncOperations = null
        })

        mysql_connect_async.acall(vargv)
    }

    function execute(query)
    {
        local rows = []

        local result = mysql_query(_syncConnection, query)

        local error_code = mysql_errno(_syncConnection)
        if (error_code != 0)
            throw mysql_error(_syncConnection) + " code: " + error_code

        if (result == null)
            return rows

        for (local i = 0, num_rows = mysql_num_rows(result); i < num_rows; ++i)
            rows.push(mysql_fetch_assoc(result))

        return rows
    }

    function executeAsync(query, callback)
    {
        if(!query.len())
            return

        if (_asyncConnection == null)
        {
            _queuedAsyncOperations.push({query = query, callback = callback})
            return
        }

        mysql_query_async(_asyncConnection, query, function(result)
        {
            local rows = []

            local error_code = mysql_errno_async(_asyncConnection)
            if (error_code != 0)
                throw mysql_error_async(_asyncConnection) + " code: " + error_code

            if (result == null)
            {
                callback(rows)
                return
            }

            for (local i = 0, num_rows = mysql_num_rows(result); i < num_rows; ++i)
                rows.push(mysql_fetch_assoc(result))

            callback(rows)
        })
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
        return "SELECT LAST_INSERT_ID() AS id;"
    }

    function insert_default_values(table_name)
    {
        return "INSERT INTO `" + table_name + "` VALUES()"
    }

    function on_duplicate_key_update()
    {
        return "ON DUPLICATE KEY UPDATE"
    }

    function get_foreign_keys_constraint()
    {
        return "SELECT @@FOREIGN_KEY_CHECKS AS foreign_keys;"
    }

    function set_foreign_keys_constraint(enabled)
    {
        return "SET FOREIGN_KEY_CHECKS = " + (enabled ? 1 : 0) + ";"
    }

    function getAutoIncrement(table_name)
    {
        local rows = execute("SHOW TABLE STATUS LIKE '" + table_name + "';")
        if(rows.len() > 0 && "Auto_increment" in rows[0] && rows[0]["Auto_increment"] != null)
            return rows[0]["Auto_increment"].tointeger()

        return 1
    }

    function setAutoIncrement(table_name, auto_increment_value)
    {
        execute("ALTER TABLE `" + table_name + "` AUTO_INCREMENT = " + auto_increment_value + ";")
    }

    function create_table_options(class_attributes)
    {
        local result = ""
        result += ("charset" in class_attributes ? " DEFAULT CHARSET=" + class_attributes.charset + " " : "")
        result += ("collate" in class_attributes ? " COLLATE=" + class_attributes.collate : "")

        return result
    }

    function create_table_member(name, attribute, default_value)
    {
        local result = ""
        result += "\t`" + name + "` " + attribute.type
        result += ("not_null" in attribute && attribute.not_null ? " NOT NULL" : "")
        result += (!("auto_increment" in attribute && attribute.auto_increment) ? " DEFAULT " + default_value : "")
        result += ("unique" in attribute && attribute.unique ? " UNIQUE" : "")
        result += ("auto_increment" in attribute && attribute.auto_increment ? " AUTO_INCREMENT" : "")
        result += ("on_update_current_timestamp" in attribute && attribute.on_update_current_timestamp ? " ON UPDATE CURRENT_TIMESTAMP" : "")

        return result
    }

    function create_table_primary_keys(class_data)
    {
        local result = "\tPRIMARY KEY("

        local i = 0, end = class_data.primary_keys.len()
        foreach (name in class_data.primary_keys)
        {
            result += "`" + name + "`"
            result += (++i != end) ? "," : ""
        }

        result += ")"

        return result
    }

    function create_table_foreign_keys(class_data)
    {
        local result = ",\n"

        local i = 0, end = class_data.foreign_keys.len()

        foreach (name, foreign_key in class_data.foreign_keys)
        {
            result += "\tFOREIGN KEY(`" + name + "`) REFERENCES `" + foreign_key.table + "`(`" + foreign_key.column +"`)"

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
        local create_table_query = execute("SHOW CREATE TABLE `" + table_name + "`;")[0]["Create Table"]
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

            if (properties.find("ON UPDATE CURRENT_TIMESTAMP") != null)
                result[name].on_update_current_timestamp <- true

            local default_captures = regex_default_value.captureall(properties)
            if (default_captures && default_captures.len() == 2)
            {
                local idx = (default_captures[0]) ? 0 : 1
                result[name].default_value <- properties.slice(default_captures[idx].begin, default_captures[idx].end)
            }
        }

        local primary_key_captures = regex_primary_keys.capture(create_table_query)
        if (primary_key_captures && primary_key_captures.len() == 2)
        {
            local content = create_table_query.slice(primary_key_captures[1].begin, primary_key_captures[1].end)
            local name_captures = regex_primary_key_name.captureall(content)

            for(local i = 0, end = name_captures.len(); i < end; i += 2)
            {
                local capture = name_captures[i + 1]

                local name = content.slice(capture.begin, capture.end)
                result[name].primary_key <- true
            }

            if (create_table_query.find("AUTO_INCREMENT") != null)
            {
                local name = content.slice(name_captures[1].begin, name_captures[1].end)
                result[name].auto_increment <- true
            }
        }

        local unique_key_captures = regex_unique_keys.capture(create_table_query)
        if (unique_key_captures && unique_key_captures.len() == 2)
        {
            local name = create_table_query.slice(unique_key_captures[1].begin, unique_key_captures[1].end)
            result[name].unique <- true
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