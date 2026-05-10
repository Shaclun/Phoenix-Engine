local operators =
{
    "=": true,
    "!=": true,
    "<": true,
    "<=": true,
    ">": true,
    ">=": true,
    "IS NULL": true,
    "IS NOT NULL": true,
    "LIKE": true,
    "IN": true
}

local function sql_escape_value(value)
{
    switch (typeof value)
    {
        case "string":
            local escaped_value = ""
            for(local i = 0, end = value.len(); i < end; ++i)
            {
                local char = value[i].tochar()
                escaped_value += (char != "'") ? char : "''"
            }

            return "'" + escaped_value + "'"

        case "null":
            return "NULL"

        case "ORM.Expression":
            return value.expression

        case "array":
            local escaped_value = ""
            foreach (v in value)
            {
                if (escaped_value.len())
                    escaped_value += ","

                escaped_value += "'" + v + "'"
            }

            return "(" + escaped_value + ")"

        default:
            return value
    }
}

local skip_auto_increment = false

/* squirreldoc (class)
*
* Class that implements query builder for creating SQL queries by using ORM.Model instances.
*
* @side       shared
* @name       ORM.Query
*
*/
class ORM.Query
{
    _class_data = null
    _query = null
    _previous_statement = null

    /* squirreldoc (constructor)
    *
    * @param      (class) model The ORM.Model class for which the query is being constructed.
    *
    */
    constructor(class_)
    {
        if (!(class_ in ORM.Model.classes))
            throw "(ORM.Query) class is not derrived from ORM.Model"

        _class_data = ORM.Model.classes[class_]
        _query = ""
    }

    function skipAutoIncrement(value)
    {
        skip_auto_increment = value
    }

    /* squirreldoc (method)
    *
    * Builds and returns the final SQL query string.
    *
    * @name       build
    * @return     (string) SQL query string.
    *
    */
    function build()
    {
        return _query + ";\n"
    }

    /* squirreldoc (method)
    *
    * Builds and returns query instance.
    *
    * @name       nextQuery
    * @return     (ORM.Query) query instance itself.
    *
    */
    function nextQuery()
    {
        _query += ";\n"
        return this
    }

    /* squirreldoc (method)
    *
    * Appends SELECT statement that selects all fields from the model's table.
    *
    * @name       select
    * @return     (ORM.Query) query instance itself.
    *
    */
    function select()
    {
        _query += "SELECT * FROM `" + _class_data.attributes.table + "`"
        return this
    }

    /* squirreldoc (method)
    *
    * Appends SELECT statement that counts the total number of rows in the model's table.
    *
    * @name       count
    * @return     (ORM.Query) query instance itself.
    *
    */
    function count()
    {
        _query += "SELECT COUNT(*) AS `count` FROM `" + _class_data.attributes.table + "`"
        return this
    }

    /* squirreldoc (method)
    *
    * Appends separate SELECT statement that counts the total number of affected rows in the model's table.
    *
    * @name       affectedCount
    * @return     (ORM.Query) query instance itself.
    *
    */
    function affectedCount()
    {
        _query += "SELECT ROW_COUNT() AS affected"
        return this
    }

    /* squirreldoc (method)
    *
    * Appends INSERT statement that inserts the specified object as a new row.
    *
    * @name       insert
    * @param      (object) object ORM.Model object to insert.
    * @return     (ORM.Query) query instance itself.
    *
    */
    function insert(object)
    {
        if (_class_data.members.len() == 1 && _class_data.auto_increment_column)
            return insertDefault()

        _query += "INSERT INTO `" + _class_data.attributes.table + "` ("
        local values = " VALUES ("

        local first = true

        foreach (idx, name in _class_data.members)
        {
            local attribute = _class_data.member_attributes[name];
            if (attribute.readonly)
                continue

            if (!skip_auto_increment && "auto_increment" in attribute && attribute.auto_increment)
                continue

            if ("not_null" in attribute && attribute.not_null && object[name] == null)
                throw "(ORM) cannot insert null into '" + _class_data.attributes.table + "." + name + "'"

            if (!first)
            {
                _query += ", "
                values += ", "
            }

            _query += "`" + name + "`"
            values += sql_escape_value(object[name])

            first = false
        }

        _query += ")"
        values += ")"
        _query += values

        return this
    }


    /* squirreldoc (method)
    *
    * Appends INSERT statement that inserts a row with default values.
    *
    * @name       insertDefault
    * @return     (ORM.Query) query instance itself.
    *
    */
    function insertDefault()
    {
        _query += ORM.engine.insert_default_values(_class_data.attributes.table)
        return this
    }

    function upsert(object)
    {
        this.insert(object)

        _query += " "
        _query += ORM.engine.on_duplicate_key_update()

        local first = true

        foreach (idx, name in _class_data.members)
        {
            if (_class_data.member_attributes[name].readonly)
                continue

            local is_primary_key = _class_data.primary_keys.find(name) != null
            if (is_primary_key)
                continue

            if (!first)
                _query += ", "

            _query += "`" + name + "`"
            _query += "="
            _query += sql_escape_value(object[name])
            first = false
        }

        return this
    }

    /* squirreldoc (method)
    *
    * Appends a SQL UPDATE statement that modifies the values of a specific database fields
    * corresponding to a given object attribute.
    *
    * @name       updateFields
    * @param      (array) fields Array containing field_name, value pairs.
    * @return     (ORM.Query) The query instance (this), allowing method chaining.
    *
    */
    function updateFields(fields)
    {
        _query += "UPDATE `" + _class_data.attributes.table + "` SET "

        local first = true

        for(local i = 0, end = fields.len(); i < end; i += 2)
        {
            local field_name = fields[i]
            local value = fields[i + 1]

            if (!(field_name in _class_data.member_attributes))
                throw "(ORM.Query) invalid field passed"

            if (_class_data.member_attributes[field_name].readonly)
                continue

            if (!first)
                _query += ", "
            else
                first = false

            _query += "`" + field_name + "` = " + sql_escape_value(value)
        }

        return this
    }


    /* squirreldoc (method)
    *
    * Appends UPDATE statement that updates the SQL table row in database that corresponds with given object.
    *
    * @name       update
    * @param      (object) object ORM.Model object containing updated values.
    * @return     (ORM.Query) query instance itself.
    *
    */
    function update(object)
    {
        _query += "UPDATE `" + _class_data.attributes.table + "` SET "

        local first = true

        foreach (idx, name in _class_data.members)
        {
            if (_class_data.member_attributes[name].readonly)
                continue

            local is_primary_key = _class_data.primary_keys.find(name) != null
            if (is_primary_key)
                continue

            if (!first)
                _query += ", "

            _query += "`" + name + "`"
            _query += "="
            _query += sql_escape_value(object[name])
            first = false
        }

        return wherePrimaryKey(object)
    }

    /* squirreldoc (method)
    *
    * Appends DELETE statement that deletes the SQL table row in database that corresponds with given object.
    *
    * @name       remove
    * @param      (object) object ORM.Model object with primary key values to match.
    * @return     (ORM.Query) query instance itself.
    *
    */
    function remove(object)
    {
        _query += "DELETE FROM `" + _class_data.attributes.table + "` WHERE "

        local values = _class_data.primary_keys.len() ? _class_data.primary_keys : _class_data.members
        local end = values.len() - 1

        foreach (idx, name in values)
        {
            _query += "`" + name + "`"
            _query += "="
            _query += sql_escape_value(object[name])
            _query += (idx != end) ? " AND " : ""
        }

        return this
    }

    function createTable()
    {
        local table = _class_data.attributes.table
        local i = 0, end = _class_data.member_attributes.len()

        _query += "CREATE TABLE IF NOT EXISTS `" + table + "` (\n"

        if (_class_data.primary_keys.len())
            ++end

        local class_ = ORM.Model.table_classes[table]

        foreach (name in _class_data.members) {
            local attribute = _class_data.member_attributes[name]
            local default_value = sql_escape_value(class_[name])

            _query += ORM.engine.create_table_member(name, attribute, default_value)
            _query += (++i != end) ? ",\n" : "\n"
        }

        if (_class_data.primary_keys.len())
            _query += ORM.engine.create_table_primary_keys(_class_data)

        if (_class_data.foreign_keys.len())
            _query += ORM.engine.create_table_foreign_keys(_class_data)

        _query += "\n) " + ORM.engine.create_table_options(_class_data.attributes)

        return this
    }

    function dropTable()
    {
        _query += "DROP TABLE IF EXISTS `" + _class_data.attributes.table + "` "
        return this
    }

    function join()
    {

        return this
    }

    /* squirreldoc (method)
    *
    * Appends predefined condition to the query.
    *
    * @name       condition
    * @param      (string) field name of the field for the condition.
    * @param      (string) operator comparison operator.
    * @param      (int|string) value value for the condition.
    * @return     (ORM.Query) query instance itself.
    *
    */
    function condition(field, operator, value)
    {
        if (!(field in _class_data.member_attributes))
            throw "(ORM.Query) member does not exist"

        if (!(operator in operators))
            throw "(ORM.Query) invalid operator '" + operator + "' passed"

        _query += " " + field + " " + operator + " " + sql_escape_value(value)
        return this
    }

    /* squirreldoc (method)
    *
    * Appends WHERE clause to the query.
    *
    * @name       where
    * @param      (string) field name of the field for the condition.
    * @param      (string) operator comparison operator.
    * @param      (int|string) value value for the condition.
    * @return     (ORM.Query) query instance itself.
    *
    */
    function where(field = null, operator = null, value = null)
    {
        if (field == null && operator == null && value == null)
        {
            _query += " WHERE "
            return this
        }

        _query += " WHERE "
        condition(field, operator, value)
        return this
    }

    /* squirreldoc (method)
    *
    * Appends WHERE clause for matching primary key values corresponding with given object.
    *
    * @name       wherePrimaryKey
    * @param      (object) object ORM.Model object containing primary key values.
    * @return     (ORM.Query) query instance itself.
    *
    */
    function wherePrimaryKey(object)
    {
        _query += " WHERE "

        local primaryKeysCount = _class_data.primary_keys.len()
        foreach (idx, name in _class_data.primary_keys)
        {
            _query += "`" + name + "`"
            _query += "="
            _query += sql_escape_value(object[name])

            if (idx != primaryKeysCount - 1)
                _query += " AND "
        }

        return this
    }

    /* squirreldoc (method)
    *
    * Appends AND condition to the query, optionally with a field, operator, and value.
    *
    * @name       and
    * @param      (string=null) field optional field for the condition.
    * @param      (string=null) operator optional comparison operator.
    * @param      (int|string=null) value optional value for the condition.
    * @return     (ORM.Query) query instance itself.
    *
    */
    function and(field = null, operator = null, value = null)
    {
        if (field == null && operator == null && value == null)
        {
            _query += " AND "
            return this
        }

        _query += " AND "
        condition(field, operator, value)
        return this
    }

    /* squirreldoc (method)
    *
    * Appends OR condition to the query, optionally with a field, operator, and value.
    *
    * @name       or
    * @param      (string=null) field optional field for the condition.
    * @param      (string=null) operator optional comparison operator.
    * @param      (any=null) value optional value for the condition.
    * @return     (ORM.Query) query instance itself.
    *
    */
    function or(field = null, operator = null, value = null)
    {
        if (field == null && operator == null && value == null)
        {
            _query += " OR "
            return this
        }

        _query += " OR "
        condition(field, operator, value)
        return this
    }

    /* squirreldoc (method)
    *
    * Appends open bracket for grouping conditions.
    *
    * @name       open_bracket
    * @return     (ORM.Query) query instance itself.
    *
    */
    function open_bracket()
    {
        _query += "("
        return this
    }

    /* squirreldoc (method)
    *
    * Appends close bracket for grouping conditions.
    *
    * @name       close_bracket
    * @return     (ORM.Query) query instance itself.
    *
    */
    function close_bracket()
    {
        _query += ")"
        return this
    }

    /* squirreldoc (method)
    *
    * Appends LIMIT clause to the query.
    *
    * @name       limit
    * @param      (int) limit maximum number of rows to return.
    * @return     (ORM.Query) query instance itself.
    *
    */
    function limit(limit)
    {
        _query += " LIMIT " + limit
        return this
    }

    /* squirreldoc (method)
    *
    * Appends OFFSET clause to the query.
    *
    * @name       offset
    * @param      (int) offset number of rows to skip.
    * @return     (ORM.Query) query instance itself.
    *
    */
    function offset(offset)
    {
        _query += " OFFSET " + offset
        return this
    }

    /* squirreldoc (method)
    *
    * Appends ORDER BY clause to the query.
    *
    * @name       orderBy
    * @param      (string) field field used for ordering elements.
    * @return     (ORM.Query) query instance itself.
    *
    */
    function orderBy(field)
    {
        _query += " ORDER BY `" + field + "`"
        return this
    }

    /* squirreldoc (method)
    *
    * Appends ASC clause used in ordering to the query.
    *
    * @name       asc
    * @return     (ORM.Query) query instance itself.
    *
    */
    function asc()
    {
        _query += " ASC"
        return this
    }

    /* squirreldoc (method)
    *
    * Appends DESC clause used in ordering to the query.
    *
    * @name       desc
    * @return     (ORM.Query) query instance itself.
    *
    */
    function desc()
    {
        _query += " DESC"
        return this
    }
}