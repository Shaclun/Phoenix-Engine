ORM.Migration <- {

    function areOptionalFieldsEqual(lhs, rhs, index)
    {
        if (index in lhs != index in rhs)
            return false

        if (!(index in lhs))
            return true

        return lhs[index] == rhs[index]
    }

    function areForeignKeysEqual(lhs, rhs)
    {
        if ("foreign_key" in lhs != "foreign_key" in rhs)
            return false

        if (!("foreign_key" in lhs))
            return true

        if (lhs.foreign_key.table.tolower() != rhs.foreign_key.table.tolower())
            return false

        if (lhs.foreign_key.column != rhs.foreign_key.column)
            return false

        if (!areOptionalFieldsEqual(lhs.foreign_key, rhs.foreign_key, "on_update"))
            return false

        if (!areOptionalFieldsEqual(lhs.foreign_key, rhs.foreign_key, "on_delete"))
            return false

        return true
    }

    function areAttributesEqual(lhs, rhs)
    {
        if (lhs.type != rhs.type)
            return false

        if (!areOptionalFieldsEqual(lhs, rhs, "not_null"))
            return false

        if (!areOptionalFieldsEqual(lhs, rhs, "primary_key"))
            return false

        if (!areOptionalFieldsEqual(lhs, rhs, "auto_increment"))
            return false

        if (!areOptionalFieldsEqual(lhs, rhs, "unique"))
            return false

        if (!areOptionalFieldsEqual(lhs, rhs, "on_update_current_timestamp"))
            return false

        if (!areForeignKeysEqual(lhs, rhs))
            return false

        return true
    }

    function areClassesEqual(lhs, rhs)
    {
        if (lhs.len() != rhs.len())
            return false

        foreach (member_name, attributes in lhs)
        {
            if (!(member_name in rhs))
                return false

            if (!areAttributesEqual(rhs[member_name], attributes))
                return false
        }

        return true
    }

    function areTypesInteger(old_type, new_type)
    {
        return ORM.engine.is_integer_type(old_type) && ORM.engine.is_integer_type(new_type)
    }

    function createNewTables()
    {
        local query = ""

        foreach (c, class_data in ORM.Model.classes)
        {
            query += ORM.Query(c)
    	        .createTable()
    	        .build()
        }

        ORM.engine.execute(query)
    }

    function getAlteredTables()
    {
        local result = {}

        foreach (c, class_data in ORM.Model.classes)
        {
            local table_name = class_data.attributes.table
            local metadata = ORM.engine.get_table_metadata(table_name)

            if (!areClassesEqual(metadata, class_data.member_attributes))
                result[c] <- metadata
        }

        return result
    }

    function migrateRows(c, metadata, old_rows, class_data)
    {
        local obj = c.instance()

        foreach (old_column in old_rows)
        {
            local original_readonly_flags = {}

            foreach (member_name, member_value in old_column)
            {
                if (!(member_name in class_data.member_attributes))
                    continue

                local attr = class_data.member_attributes[member_name]

                local oldType = metadata[member_name].type.toupper()
                local newType = attr.type.toupper()

                // Check types with regex to handle different metadata formats returned by
                // "SHOW CREATE TABLE" across different MySQL versions — type strings may vary slightly
                // (e.g. "int(11)" vs "int", or differing collation/charset info)
                if (areTypesInteger(oldType, newType))
                    obj[member_name] = member_value
                else if (newType == oldType)
                    obj[member_name] = member_value
                else
                    obj[member_name] = c[member_name]

                original_readonly_flags[member_name] <- attr.readonly
                attr.readonly = false
            }

            obj.insert()

            foreach (member_name, old_flag in original_readonly_flags)
                class_data.member_attributes[member_name].readonly = old_flag
        }
    }

    function executeTempTableAction(c, callback)
    {
        local class_data = ORM.Model.classes[c]
        local table_name = class_data.attributes.table
        local temporary_table_name = "_temp_" + table_name + "_"

        // Set table name to temporary and create entry in table_classes
        class_data.attributes.table = temporary_table_name
        ORM.Model.table_classes[temporary_table_name] <- c

        local failed = false

        try
        {
            callback(temporary_table_name)
        }
        catch (errorMsg)
        {
            failed = true

            local stackinfos = getstackinfos(2)
            error("[error] " + errorMsg + " " + stackinfos.src + ":" + stackinfos.line)
        }

        // Revert table name to original and delete temporary table entry in table_classes
        class_data.attributes.table = table_name
        delete ORM.Model.table_classes[temporary_table_name]

        return failed
    }

    function migrate()
    {
        local altered_tables = getAlteredTables()
        if (altered_tables.len() == 0)
        {
            print("ORM: Nothing to migrate!")
            return true
        }

        print("ORM: Migration started")

        ORM.Query.skipAutoIncrement(true)

        local migration_tables = {}
        local migration_failed = false

        foreach (c, metadata in altered_tables)
        {
            local class_data = ORM.Model.classes[c]
            local old_rows = ORM.engine.execute(ORM.Query(c).select().build())
            local auto_increment_idx = ORM.engine.getAutoIncrement(class_data.attributes.table)

            migration_failed = executeTempTableAction(c, function(temporary_table_name)
            {
                // Drop old temporary table and create an empty one
                ORM.engine.execute(ORM.Query(c).dropTable().build())
                ORM.engine.execute(ORM.Query(c).createTable().build())

                migration_tables[temporary_table_name] <- c
                migrateRows(c, metadata, old_rows, class_data)

                // Restoring original auto increment idx
                ORM.engine.setAutoIncrement(temporary_table_name, auto_increment_idx)
            })

            if (migration_failed)
                break
        }

        if (!migration_failed)
            finishMigration(migration_tables)
        else
            revertMigration(migration_tables)

        ORM.Query.skipAutoIncrement(false)

        print("ORM: Migration end")

        return migration_failed
    }

    function finishMigration(migration_tables)
    {
        foreach (temporary_table_name, c in migration_tables)
        {
            local table_name = ORM.Model.classes[c].attributes.table

            // Drop original table
            ORM.engine.execute(ORM.Query(c).dropTable().build())

            // Rename temporary table to original name (special case that needs to be processed as raw query)
            ORM.engine.execute("ALTER TABLE `" + temporary_table_name + "` RENAME TO `" + table_name + "`;")

            print("ORM: Migrating '" + table_name + "' Succeeded!")
        }
    }

    function revertMigration(migration_tables)
    {
        foreach (c in migration_tables)
        {
            local table_name = ORM.Model.classes[c].attributes.table

            executeTempTableAction(c, function(temporary_table_name)
            {
                // Drop temp table
                ORM.engine.execute(ORM.Query(c).dropTable().build())
            })

            print("ORM: Reverting migration '" + table_name + "'")
        }
    }
}