local foreign_key_actions =
{
    "NO ACTION": true,
    "RESTRICT": true,
    "CASCADE": true,
    "SET NULL": true
}

/* squirreldoc (class)
*
* This table represents core ORM features.
*
* @static
* @side		shared
* @name		ORM
*
*/
ORM <- {
    /* squirreldoc (property)
    *
    * Represents used SQL engine by the ORM.
    *
    * @name     engine
    * @note		You need to create & set this field initially before you start using ORM.
    * @return	(ORM.Engine)
    *
    */
    engine = null

    /* squirreldoc (property)
    *
    * Represents automatic migration status.
    * Set this field to `true` only when you want to recreate SQL tables and preserve rows from original tables.
    *
    * @name     migration_enabled
    * @return	(bool)
    *
    */
    migration_enabled = false

    /* squirreldoc (callback)
    *
    * Represents callback after async connection.
    *
    * @name     onAsyncConnect
    * @param    (connection) connection object
    *
    */
    onAsyncConnect = null

    /* squirreldoc (callback)
    *
    * Represents callback after sync connection.
    *
    * @name     onSyncConnect
    * @param    (connection) connection object
    *
    */
    onSyncConnect = null

    function init()
    {
        validateForeignKeys()

        local fk_constraint = ORM.engine.execute(ORM.engine.get_foreign_keys_constraint())[0]["foreign_keys"]
        ORM.engine.execute(ORM.engine.set_foreign_keys_constraint(false))

        Migration.createNewTables()

        if (migration_enabled && !Migration.migrate())
            print("ORM: Migration completed successfully")

        ORM.engine.execute(ORM.engine.set_foreign_keys_constraint(fk_constraint))
    }

    function validateForeignKeys()
    {
        foreach (class_data in ORM.Model.classes)
        {
            foreach (foreign_key in class_data.foreign_keys)
            {
                local foreign_key_table = foreign_key.table
                if (!(foreign_key_table in ORM.Model.table_classes))
                    throw "(ORM) foreign key table '" + foreign_key_table + "' is invalid"

                local foreign_class = ORM.Model.table_classes[foreign_key_table]
                local foreign_class_member_attributes = ORM.Model.classes[foreign_class].member_attributes

                local foreign_key_column = foreign_key.column
                if (!(foreign_key_column in foreign_class_member_attributes))
                    throw "(ORM) foreign class field '" + foreign_key_table + "." + foreign_key_column + "' doesn't exist"

                if ("on_update" in foreign_key && !(foreign_key.on_update in foreign_key_actions))
                    throw "(ORM) foreign key '" + foreign_key_table + "." + foreign_key_column + "' has invalid value for 'on_update' action"

                if ("on_delete" in foreign_key && !(foreign_key.on_delete in foreign_key_actions))
                    throw "(ORM) foreign key '" + foreign_key_table + "." + foreign_key_column + "' has invalid value for 'on_delete' action"

                local foreign_attributes = foreign_class_member_attributes[foreign_key_column]
                if (!("primary_key" in foreign_attributes && foreign_attributes.primary_key)
                &&  !("unique" in foreign_attributes && foreign_attributes.unique))
                        throw "(ORM) foreign class field '" + foreign_key_table + "." + foreign_key_column + "' is not a primary_key or unique"
            }
        }
    }
}

// Disabled - tables already exist, managed manually
// addEventHandler("onInit", ORM.init.bindenv(ORM), 1)