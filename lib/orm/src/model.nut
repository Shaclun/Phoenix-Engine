local default_callback = function(result) {}

/* squirreldoc (class)
*
* Class that allows you to implement save/load logic for SQL table via inheritance.
*
* @side       shared
* @name       ORM.Model
*
*/
class ORM.Model
{
    static classes = {}
    static table_classes = {}

    static function update_instance_values(instance, table)
    {
        local class_data = classes[this]

        foreach (field_name, field_value in table)
        {
            local attributes = class_data.member_attributes[field_name]
            if(attributes.type in ORM.engine.sql_to_sq_type)
                field_value = ORM.engine.sql_to_sq_type[attributes.type](field_value)

            instance[field_name] = field_value
        }
    }

    static function convert_to_instance(table)
    {
        local class_data = classes[this]
        local primary_key = getPrimaryKey(table)

        if (primary_key != null && primary_key in class_data.cached_objects)
        {
            if (class_data.cached_objects[primary_key] == null)
                delete class_data.cached_objects[primary_key]
            else
                return class_data.cached_objects[primary_key]
        }

        local instance = this.instance()
        update_instance_values(instance, table)

        if (primary_key != null)
            class_data.cached_objects[primary_key] <- instance.weakref()

        instance.afterModelLoad()

        return instance
    }

    /* universal */ function getPrimaryKey(object = null)
    {
        local class_data = null
        switch (typeof this)
        {
            case "instance":
                object = this
                class_data = classes[this.getclass()]
                break

            case "class":
                class_data = classes[this]
                break
        }

        local primary_keys = class_data.primary_keys
        switch (primary_keys.len())
        {
            case 0: return null
            case 1: return object[primary_keys[0]]
        }

        local primary_key = ""
        foreach(key in primary_keys)
            primary_key += object[key].tostring()

        return primary_key
    }

    static function find_query(filter_callback)
    {
        local query = ORM.Query(this)
            .select()

        return filter_callback(query).build()
    }

    static function find_result(rows)
    {
        local result = []
        foreach (table in rows)
            result.push(convert_to_instance(table))

        return result
    }

    /* squirreldoc (method)
    *
    * Returns array of instances found in database based on predetermined conditions defined in filter callback.
    *
    * @static
    * @name		find
    * @param	(callback) filter_callback filter callback that receives [ORM.Query](../../../shared-classes/general/ORM.Query/) object in argument and must return it.
    * @return	(array) array containing instances.
    *
    */
    static function find(filter_callback)
    {
        local rows = ORM.engine.execute(find_query(filter_callback))
        return find_result(rows)
    }

    /* squirreldoc (method)
    *
    * Executes result callback that receives array of instances as argument found in database based on predetermined conditions defined in filter callback.
    *
    * @static
    * @name		findAsync
    * @param	(callback) filter_callback filter callback that receives [ORM.Query](../../../shared-classes/general/ORM.Query/) object in argument and must return it.
    * @param	(callback) result_callback result callback that receives array containing instances in argument.
    *
    */
   static function findAsync(filter_callback, result_callback)
   {
        local query = ORM.Query(this)
            .select()
        local self = this

        ORM.engine.executeAsync(find_query(filter_callback), function(rows)
        {
            result_callback(self.find_result(rows))
        })
   }

    static function findAssoc_query(field_name, filter_callback)
    {
        local class_data = classes[this]
        if (!(field_name in class_data.member_attributes))
           throw "(ORM.Model) field name '" + field_name + "' is not serialized"

        local query = ORM.Query(this)
            .select()

        return filter_callback(query).build()
    }

    static function findAssoc_result(field_name, rows)
    {
        local result = {}
        foreach (table in rows)
            result[table[field_name]] <- convert_to_instance(table)

        return result
    }

    /* squirreldoc (method)
    *
    * Returns table of instances found in database based on predetermined conditions defined in filter callback.
    *
    * @static
    * @name		findAssoc
    * @param	(string) field_name name of unique SQL column that will be used to index returned table.
    * @param	(callback) filter_callback filter callback that receives [ORM.Query](../../../shared-classes/general/ORM.Query/) object in argument and must return it.
    * @return	(table) table containing instances indexed by field_name.
    *
    */
    static function findAssoc(field_name, filter_callback)
    {

        local rows = ORM.engine.execute(findAssoc_query(field_name, filter_callback))
        return findAssoc_result(field_name, rows)
    }

    /* squirreldoc (method)
    *
    * Executes result callback that receives table of instances as argument found in database based on predetermined conditions defined in filter callback.
    *
    * @static
    * @name		findAssocAsync
    * @param	(string) field_name name of unique SQL column that will be used to index returned table.
    * @param	(callback) filter_callback filter callback that receives [ORM.Query](../../../shared-classes/general/ORM.Query/) object in argument and must return it.
    * @param	(callback) result_callback result callback that receives table containing instances indexed by field_name in argument.
    *
    */
   static function findAssocAsync(field_name, filter_callback, result_callback)
   {
        local self = this

        ORM.engine.executeAsync(findAssoc_query(field_name, filter_callback), function(rows)
        {
            result_callback(self.findAssoc_result(field_name, rows))
        })
   }

    static function findOne_query(filter_callback)
    {
        local query = ORM.Query(this)
            .select()

        return filter_callback(query).limit(1).build()
    }

    static function findOne_result(rows)
    {
        if (!rows.len())
            return null

        return convert_to_instance(rows[0])
    }

    /* squirreldoc (method)
    *
    * Returns one instances found in database based on predetermined conditions defined in filter callback.
    *
    * @static
    * @name		findOne
    * @param	(callback) filter_callback filter callback that receives [ORM.Query](../../../shared-classes/general/ORM.Query/) object in argument and must return it.
    * @return	(instance|null) instance of class or null if such instance doesn't exist.
    *
    */
    static function findOne(filter_callback)
    {
        local query = ORM.Query(this)
            .select()

        local rows = ORM.engine.execute(findOne_query(filter_callback))
        return findOne_result(rows)
    }

    /* squirreldoc (method)
    *
    * Executes result callback that receives one instances as argument found in database based on predetermined conditions defined in filter callback.
    *
    * @static
    * @name		findOneAsync
    * @param	(callback) callback filter callback that receives [ORM.Query](../../../shared-classes/general/ORM.Query/) object in argument and must return it.
    * @param	(callback) result_callback result callback that receives instance of class or null if such instance doesn't exist in argument.
    *
    */
    static function findOneAsync(filter_callback, result_callback)
    {
        local self = this

        ORM.engine.executeAsync(findOne_query(filter_callback), function(rows)
        {
            result_callback(self.findOne_result(rows))
        })
    }

    static function findAll_query()
    {
        local query = ORM.Query(this)
            .select()

        return query.build()
    }

    static function findAll_result(rows)
    {
        local result = []
        foreach (table in rows)
            result.push(convert_to_instance(table))

        return result
    }

    /* squirreldoc (method)
    *
    * Returns all of the instances from database.
    *
    * @static
    * @name		findAll
    * @return	(array) array containing all instances.
    *
    */
    static function findAll()
    {
        local query = ORM.Query(this)
            .select()

        local rows = ORM.engine.execute(findAll_query())
        return findAll_result(rows)
    }

    /* squirreldoc (method)
    *
    * Executes result callback that receives all of the instances as argument from database.
    *
    * @static
    * @name		findAllAsync
    * @param	(callback) result_callback result callback that receives array containing all instances in argument.
    *
    */
    static function findAllAsync(result_callback)
    {
        local self = this

        ORM.engine.executeAsync(findAll_query(), function(rows)
        {
            result_callback(self.findAll_result(rows))
        })
    }

    static function findAllAssoc_query(field_name)
    {
        local class_data = classes[this]
        if (!(field_name in class_data.member_attributes))
            throw "(ORM.Model) field name '" + field_name + "' is not serialized"

        local query = ORM.Query(this)
            .select()

        return query.build()
    }

    static function findAllAssoc_result(field_name, rows)
    {
        local result = {}
        foreach (table in rows)
            result[table[field_name]] <- convert_to_instance(table)

        return result
    }

    /* squirreldoc (method)
    *
    * Returns table of all instances found in database.
    *
    * @static
    * @name		findAllAssoc
    * @param	(string) field_name name of unique SQL column that will be used to index returned table.
    * @return	(table) table containing instances indexed by field_name.
    *
    */
    static function findAllAssoc(field_name)
    {
        local rows = ORM.engine.execute(findAllAssoc_query(field_name))
        return findAllAssoc_result(field_name, rows)
    }

    /* squirreldoc (method)
    *
    * Executes result callback that receives table of all instances as argument found in database.
    *
    * @static
    * @name		findAllAssocAsync
    * @param	(string) field_name name of unique SQL column that will be used to index returned table.
    * @param	(callback) result_callback result callback that receives table containing instances indexed by field_name in argument.
    *
    */
    static function findAllAssocAsync(field_name, result_callback)
    {
        local self = this

        ORM.engine.executeAsync(findAllAssoc_query(field_name), function(rows)
        {
            result_callback(self.findAllAssoc_result(field_name, rows))
        })
    }

    static function count_query(filter_callback)
    {
        local query = ORM.Query(this)
            .count()

        if (filter_callback)
            query = filter_callback(query)

        return query.build()
    }

    /* squirreldoc (method)
    *
    * Returns count of SQL entries from database based on predetermined conditions defined in passed callback.
    *
    * @static
    * @name		count
    * @param	(callback=null) filter_callback optional filter callback that receives [ORM.Query](../../../shared-classes/general/ORM.Query/) object in argument and must return it.
    * @return	(int) Count of SQL entries in database.
    *
    */
    static function count(filter_callback = null)
    {
        local rows = ORM.engine.execute(count_query(filter_callback))
        return rows[0]["count"]
    }

    /* squirreldoc (method)
    *
    * Executes result callback that receives count of SQL entries as argument from database based on predetermined conditions defined in filter callback.
    *
    * @static
    * @name		countAsync
    * @param	(callback) filter_callback optional filter callback that receives [ORM.Query](../../../shared-classes/general/ORM.Query/) object in argument and must return it.
    * @param	(callback) result_callback result callback that receives count of SQL entries in database as argument.
    *
    */
    static function countAsync(filter_callback, result_callback)
    {
        local self = this

        ORM.engine.executeAsync(count_query(filter_callback), function(rows)
        {
            result_callback(rows[0]["count"])
        })
    }

    static function children_query(child_class)
    {
        if (!(child_class in classes))
            throw "(ORM.Model) child class is not ORM model"

        local class_data = classes[this.getclass()]
        local child_class_data = classes[child_class]

        local foreign_key_field = null
        local foreign_key = null

        foreach (field, foreign_key_meta in child_class_data.foreign_keys)
        {
            if (foreign_key_meta.table != class_data.attributes.table)
                continue

            foreign_key_field = field
            foreign_key = foreign_key_meta
            break
        }

        if (!foreign_key_field)
            throw "(ORM.Model) child class is not foreign key of current object"

        local foreign_key_id = this[foreign_key.column]
        local query = @(q) q.where(foreign_key_field, "=", foreign_key_id)

        return query
    }

    /* squirreldoc (method)
    *
    * Returns array of instances found in database that are defined as foreign key with relation one to many by given child class.
    *
    * @name		children
    * @param	(class) child_class child class that is used as foreign key.
    * @return	(array) array containing child instances.
    *
    */
    function children(child_class)
    {
        return child_class.find(children_query(child_class))
    }

    /* squirreldoc (method)
    *
    * Executes result callback that receives array of instances as argument found in database that are defined as foreign key with relation one to many by given child class.
    *
    * @name		childrenAsync
    * @param	(class) child_class child class that is used as foreign key.
    * @param	(callback) result_callback result callback that receives array containing child instances in argument.
    *
    */
    function childrenAsync(child_class, result_callback)
    {

        child_class.findAsync(children_query(child_class), result_callback)
    }

    function childrenAssoc_query(field_name, child_class)
    {
        local class_data = classes[this.getclass()]
        local child_class_data = classes[child_class]

        if (!(field_name in child_class_data.member_attributes))
            throw "(ORM.Model) field name '" + field_name + "' is not serialized"

        if (!(child_class in classes))
            throw "(ORM.Model) child class is not ORM model"

        local foreign_key_field = null
        local foreign_key = null

        foreach (field, foreign_key_meta in child_class_data.foreign_keys)
        {
            if (foreign_key_meta.table != class_data.attributes.table)
                continue

            foreign_key_field = field
            foreign_key = foreign_key_meta
            break
        }

        if (!foreign_key_field)
            throw "(ORM.Model) child class is not foreign key of current object"

        local foreign_key_id = this[foreign_key.column]
        local query = @(q) q.where(foreign_key_field, "=", foreign_key_id)

        return query
    }

    /* squirreldoc (method)
    *
    * Returns table of instances found in database that are defined as foreign key with relation one to many by given child class.
    *
    * @name		childrenAssoc
    * @param	(string) field_name name of unique SQL column from child class that will be used to index returned table.
    * @param	(class) child_class child class that is used as foreign key.
    * @return	(table) table containing child instances indexed by field_name.
    *
    */
    function childrenAssoc(field_name, child_class)
    {
        return child_class.findAssoc(field_name, childrenAssoc_query(field_name, child_class))
    }

    /* squirreldoc (method)
    *
    * Executes result callback that receives table of instances as argument found in database that are defined as foreign key with relation one to many by given child class.
    *
    * @name		childrenAssocAsync
    * @param	(string) field_name name of unique SQL column from child class that will be used to index returned table.
    * @param	(class) child_class child class that is used as foreign key.
    * @param	(callback) result_callback result callback that receives table containing child instances indexed by field_name in argument.
    *
    */
    function childrenAssocAsync(field_name, child_class, result_callback)
    {
        child_class.findAssocAsync(field_name, childrenAssoc_query(field_name, child_class), result_callback)
    }

    function parent_query(parent_class)
    {
        if (!(parent_class in classes))
            throw "(ORM.Model) parent class is not ORM model"

        local class_data = classes[this.getclass()]
        local parent_class_data = classes[parent_class]

        local foreign_key_field = null
        local foreign_key = null

        foreach (field, foreign_key_meta in class_data.foreign_keys)
        {
            if (foreign_key_meta.table != parent_class_data.attributes.table)
                continue

            foreign_key_field = field
            foreign_key = foreign_key_meta
            break
        }

        if (!foreign_key_field)
            throw "(ORM.Model) parent class is not foreign key of current object"

        local foreign_key_id = this[foreign_key_field]
        local query = @(q) q.where(foreign_key.column, "=", foreign_key_id)

        return query
    }

    /* squirreldoc (method)
    *
    * Returns instance found in database thas is defined as foreign key with relation one to one by given parent class.
    *
    * @name		parent
    * @param	(class) parent_class parent class that is used as foreign key.
    * @return	(instance) instance of parent class.
    *
    */
    function parent(parent_class)
    {
        return parent_class.findOne(parent_query(parent_class))
    }

    /* squirreldoc (method)
    *
    * Executes result callback that receives instance as argument found in database thas is defined as foreign key with relation one to one by given parent class.
    *
    * @name		parentAsync
    * @param	(class) parent_class parent class that is used as foreign key.
    * @param	(callback) result_callback result callback that receives instance of parent class in argument.
    *
    */
    function parentAsync(parent_class, result_callback)
    {
        parent_class.findOneAsync(parent_query(parent_class), result_callback)
    }

    function refresh_query()
    {
        local query = ORM.Query(this.getclass())
            .select()
            .wherePrimaryKey(this)
            .build()

        return query
   }

    /* squirreldoc (method)
    *
    * Pulls the row data from SQL table in database and applies it to the current instance.
    *
    * @name		refresh
    *
    */
    function refresh()
    {
        local rows = ORM.engine.execute(refresh_query())
        if (!rows.len())
            throw "(ORM) Unable to refresh object with primary key '" + this.getPrimaryKey() + "'"

        update_instance_values(this, rows[0])
    }

    /* squirreldoc (method)
    *
    * Pulls the row data from SQL table in database and applies it to the current instance and executes result callback that receives instance as argument.
    *
    * @name		refreshAsync
    * @param	(callback) result_callback result callback that receives updated current instance in argument.
    *
    */
    function refreshAsync(result_callback)
    {
        local self = this

        ORM.engine.executeAsync(refresh_query(), function(rows)
        {
            if (!rows.len())
                throw "(ORM) Unable to refresh object with primary key '" + self.getPrimaryKey() + "'"

            self.update_instance_values(self, rows[0])
            result_callback(self)
        })
    }

    function insert_query(class_, class_data)
    {
        local query = ORM.Query(class_)
            .insert(this)
            .build()

        return query
    }

    /* squirreldoc (method)
    *
    * Inserts the current instance into SQL table as row in database.
    *
    * @name		insert
    * @return	(bool) `true` if insertion was successful, otherwise `false`.
    *
    */
    function insert()
    {
        local class_ = this.getclass()
        local class_data = classes[class_]

        beforeModelInsert()

        ORM.engine.execute(insert_query(class_, class_data))
        
        if (class_data.auto_increment_column) {
            local rows = ORM.engine.execute(ORM.engine.last_insert_id())
            if (!rows.len())
                return false
            this[class_data.auto_increment_column] = rows[0]["id"]
        }

        if (this.getPrimaryKey())
            class_data.cached_objects[this.getPrimaryKey()] <- this.weakref()

        afterModelInsert()

        return true
    }

        /* squirreldoc (method)
    *
    * Inserts the current instance into SQL table as row in database and executes result callback that receives current instance as argument.
    *
    * @name		insertAsync
    * @param	(callback) result_callback result callback that receives success status in argument.
    *
    */
    function insertAsync(result_callback = default_callback)
    {
        local class_ = this.getclass()
        local class_data = classes[class_]

        beforeModelInsert()

        local self = this

        ORM.engine.executeAsync(insert_query(class_, class_data), function(rows)
        {
            if (class_data.auto_increment_column) {
                // Need to get LAST_INSERT_ID in a separate query
                ORM.engine.executeAsync(ORM.engine.last_insert_id(), function(idRows) {
                    if (!idRows.len()) {
                        result_callback(null)
                        return
                    }

                    local insertedId = idRows[0]["id"]
                    self[class_data.auto_increment_column] = insertedId

                    if (self.getPrimaryKey())
                        class_data.cached_objects[self.getPrimaryKey()] <- self.weakref()

                    result_callback(insertedId)
                    self.afterModelInsert()
                })
            } else {
                if (self.getPrimaryKey())
                    class_data.cached_objects[self.getPrimaryKey()] <- self.weakref()

                result_callback(true)
                self.afterModelInsert()
            }
        })
    }

    function save_query(class_)
    {
        local query = ORM.Query(class_)
            .update(this)
            .build()

        return query
    }

    /* squirreldoc (method)
    *
    * Pushes the current instance values into SQL table row in database.
    *
    * @name		save
    *
    */
    function save()
    {
        local class_ = this.getclass()
        local class_data = classes[class_]

        if (class_data.members.len() == class_data.primary_keys.len())
            return

        beforeModelSave()

        ORM.engine.execute(save_query(class_))

        afterModelSave()
    }

    /* squirreldoc (method)
    *
    * Pushes the current instance values into SQL table row in database and executes result callback that receives current instance as argument.
    *
    * @name		saveAsync
    * @param	(callback) result_callback result callback that receives current instance in argument.
    *
    */
    function saveAsync(result_callback = default_callback)
    {
        local class_ = this.getclass()
        local class_data = classes[class_]

        if (class_data.members.len() == class_data.primary_keys.len())
            return

        beforeModelSave()
        local self = this

        ORM.engine.executeAsync(save_query(class_), function(rows)
        {
            result_callback(self)
            self.afterModelSave()
        })
    }

    function upsert_query(class_, class_data)
    {
        local query = ORM.Query(class_)
            .count()
            .wherePrimaryKey(this)
            .nextQuery()
            .upsert(this)
            .build()

        return query
    }

    /* squirreldoc (method)
    *
    * Inserts the current instance into the SQL table, or updates the existing row if a conflict occurs and returns status if the row was created.
    *
    * @name		upsert
    * @return	(bool) `true` if a new row was created, `false` if an existing row was updated.
    *
    */
    function upsert()
    {
        local class_ = this.getclass()
        local class_data = classes[class_]

        local rows = ORM.engine.execute(upsert_query(class_, class_data))
        local created = rows.len() && rows[0]["count"] == 0

        if (class_data.auto_increment_column && created) {
            local idRows = ORM.engine.execute(ORM.engine.last_insert_id())
            if (idRows.len())
                this[class_data.auto_increment_column] = idRows[0]["id"]
        }

        if (this.getPrimaryKey())
            class_data.cached_objects[this.getPrimaryKey()] <- this.weakref()

        return created
    }

    /* squirreldoc (method)
    *
    * Inserts the current instance into the SQL table, or updates the existing row if a conflict occurs and executes a result callback with the operation status.
    *
    * @name		upsertAsync
    * @param	(callback) result_callback result callback that receives `true` if a new row was created, `false` if an existing row was updated.
    *
    */
    function upsertAsync(result_callback = default_callback)
    {
        local class_ = this.getclass()
        local class_data = classes[class_]

        local self = this

        ORM.engine.executeAsync(upsert_query(class_, class_data), function(rows)
        {
            local created = rows.len() && rows[0]["count"] == 0

            if (class_data.auto_increment_column && created) {
                ORM.engine.executeAsync(ORM.engine.last_insert_id(), function(idRows) {
                    if (idRows.len())
                        self[class_data.auto_increment_column] = idRows[0]["id"]

                    if (self.getPrimaryKey())
                        class_data.cached_objects[self.getPrimaryKey()] <- self.weakref()

                    result_callback(created)
                })
            } else {
                if (self.getPrimaryKey())
                    class_data.cached_objects[self.getPrimaryKey()] <- self.weakref()

                result_callback(created)
            }
        })
    }

    function remove_query(class_)
    {
        local query_count = ORM.Query(class_)
            .count()
            .build()

        local query_remove = ORM.Query(class_)
            .remove(this)
            .build()

        return query_count + query_remove + query_count
    }

    /* squirreldoc (method)
    *
    * Removes the SQL table row in database that corresponds to current instance.
    *
    * @name		remove
    * @return	(bool) `true` if remove was successful, otherwise `false`.
    *
    */
    function remove()
    {
        local class_ = this.getclass()
        local class_data = classes[class_]

        beforeModelDelete()

        local rows = ORM.engine.execute(remove_query(class_))
        local removed = rows[0].count != rows[1].count

        if (removed)
        {
            delete class_data.cached_objects[this.getPrimaryKey()]
            afterModelDelete()
        }

        return removed
    }

    /* squirreldoc (method)
    *
    * Removes the SQL table row in database that corresponds to current instance and executes result callback that receives success status as argument.
    *
    * @name		removeAsync
    * @param	(callback) result_callback result callback that receives success status in argument.
    *
    */
    function removeAsync(result_callback = default_callback)
    {
        local class_ = this.getclass()
        local class_data = classes[class_]

        beforeModelDelete()

        local self = this

        ORM.engine.executeAsync(remove_query(class_), function(rows)
        {
            local removed = rows[0].count != rows[1].count

            if (removed)
            {
                delete class_data.cached_objects[self.getPrimaryKey()]
                self.afterModelDelete()
            }

            result_callback(removed)

        })
    }

    /* squirreldoc (method)
    *
    * Deletes model instance from internal ORM cache, useful when you want to forget about the object on squirrel side and leave it in database.
    *
    * @name		erase
    *
    */
    function erase()
    {
        local class_ = this.getclass()
        local class_data = classes[class_]
        local primary_key = this.getPrimaryKey()

        if (primary_key in class_data.cached_objects)
            delete class_data.cached_objects[primary_key]
    }

    /* squirreldoc (method)
    *
    * Updates a specific field in the database for rows matching a dynamic filter,
    * and returns operation status.
    *
    * @name     update
    * @param    (array) fields Array containing field_name, value pairs.
    * @param    (function) filter_callback Function that applies filtering logic to the query (receives the query as an argument).
    * @return   (bool) `true` if update was successfull, otherwise `false`.
    *
    */
    function update(fields, filter_callback)
    {
        local self = this
        local query = ORM.Query(this.getclass())

        query.updateFields(fields)

        filter_callback(query)

        query.nextQuery()
            .affectedCount()

        local rows = ORM.engine.execute(query.build())
        local affected = rows.len() > 0

        if(affected)
        {
            for(local i = 0, end = fields.len(); i < end; i += 2)
            {
                local field_name = fields[i]
                local value = fields[i + 1]

                self[field_name] = value
            }
        }

        return affected
    }

    /* squirreldoc (method)
    *
    * Updates a specific field in the database for rows matching a dynamic filter,
    * and executes a result callback with the operation status.
    *
    * @name     updateAsync
    * @param    (array) fields Array containing field_name, value pairs.
    * @param    (function) filter_callback Function that applies filtering logic to the query (receives the query as an argument).
    * @param    (function) result_callback Callback function that receives a boolean indicating whether the update was successful.
    *
    */
    function updateAsync(fields, filter_callback, result_callback = default_callback)
    {
        local self = this
        local query = ORM.Query(this.getclass())

        query.updateFields(fields)

        filter_callback(query)

        query.nextQuery()
            .affectedCount()

        ORM.engine.executeAsync(query.build(), function(rows)
        {
            local affected = rows.len() > 0
            if(affected)
            {
                for(local i = 0, end = fields.len(); i < end; i += 2)
                {
                    local field_name = fields[i]
                    local value = fields[i + 1]

                    self[field_name] = value
                }
            }

            result_callback(affected)
        })
    }

    /* squirreldoc (method)
    *
    * Callback method called after loading model instance from database.
    *
    * @name		afterModelLoad
    * @note     This method is meant to be overloaded in order to define your custom logic.
    *
    */
    function afterModelLoad()
    {
    }

    /* squirreldoc (method)
    *
    * Callback method called before pushing current instance values into SQL table row in database.
    *
    * @name		beforeModelSave
    * @note     This method is meant to be overloaded in order to define your custom logic.
    *
    */
    function beforeModelSave()
    {
    }

    /* squirreldoc (method)
    *
    * Callback method called after pushing current instance values into SQL table row in database.
    *
    * @name		afterModelSave
    * @note     This method is meant to be overloaded in order to define your custom logic.
    *
    */
    function afterModelSave()
    {
    }

    /* squirreldoc (method)
    *
    * Callback method called before inserting the current instance into SQL table as row in database.
    *
    * @name		beforeModelInsert
    * @note     This method is meant to be overloaded in order to define your custom logic.
    *
    */
    function beforeModelInsert()
    {
    }

    /* squirreldoc (method)
    *
    * Callback method called after inserting the current instance into SQL table as row in database.
    *
    * @name		afterModelInsert
    * @note     This method is meant to be overloaded in order to define your custom logic.
    *
    */
    function afterModelInsert()
    {
    }

    /* squirreldoc (method)
    *
    * Callback method called before removing the SQL table row in database that corresponds to current instance.
    *
    * @name		beforeModelDelete
    * @note     This method is meant to be overloaded in order to define your custom logic.
    *
    */
    function beforeModelDelete()
    {
    }

    /* squirreldoc (method)
    *
    * Callback method called after removing the SQL table row in database that corresponds to current instance.
    *
    * @name		afterModelDelete
    * @note     This method is meant to be overloaded in order to define your custom logic.
    *
    */
    function afterModelDelete()
    {
    }

    /* squirreldoc (method)
    *
    * Inserts given instances into SQL table as row in database.
    *
    * @static
    * @name		insertBatch
    * @param    (array) models containing ORM.Model objects.
    * @return	(array) array containing inserted ORM.Model objects.
    *
    */
    static function insertBatch(models)
    {
        local query_string = ""

        foreach(model in models)
        {
            local class_ = model.getclass()
            local class_data = classes[class_]

            query_string += model.insert_query(class_, class_data)
        }

        local rows = ORM.engine.execute(query_string)
        if (!rows.len())
            return null

        foreach(index, row in rows)
        {
            local model = models[index]

            local class_ = model.getclass()
            local class_data = model.classes[class_]

            model[class_data.auto_increment_column] = row["id"]

            if (model.getPrimaryKey())
                class_data.cached_objects[model.getPrimaryKey()] <- model.weakref()

            model.afterModelInsert()
        }

        return models
    }

    /* squirreldoc (method)
    *
    * Inserts given instances into SQL table as row in database and executes result callback that receives given instances as argument
    *
    * @static
    * @name     insertBatchAsync
    * @param    (array) models containing ORM.Model objects.
    * @return	(callback) result_callback result callback that receives array containing inserted ORM.Model objects as argument on success, or `null` on failure.
    *
    */
    static function insertBatchAsync(models, result_callback = default_callback)
    {
        local query_string = ""

        foreach(model in models)
        {
            local class_ = model.getclass()
            local class_data = classes[class_]

            query_string += model.insert_query(class_, class_data)
        }

        ORM.engine.executeAsync(query_string, function(rows)
        {
            if (!rows.len())
            {
                result_callback(null)
                return
            }

            foreach(index, row in rows)
            {
                local model = models[index]

                local class_ = model.getclass()
                local class_data = model.classes[class_]

                model[class_data.auto_increment_column] = row["id"]

                if (model.getPrimaryKey())
                    class_data.cached_objects[model.getPrimaryKey()] <- model.weakref()

                model.afterModelInsert()
            }

            result_callback(models)
        })
    }

    /* squirreldoc (method)
    *
    * Pushes given instances values into SQL table row in database.
    *
    * @static
    * @name		saveBatch
    * @param	(array) models containing ORM.Model objects.
    *
    */
    static function saveBatch(models)
    {
        local query_string = ""
        foreach(model in models)
        {
            local class_ = model.getclass()
            local class_data = classes[class_]

            if (class_data.members.len() == class_data.primary_keys.len())
                return

            query_string += model.save_query(class_)
        }

        beforeModelSave()

        ORM.engine.execute(query_string)

        foreach(model in models)
        {
            local class_ = model.getclass()
            local class_data = classes[class_]

            if (class_data.members.len() == class_data.primary_keys.len())
                continue

            model.afterModelSave()
        }

    }

    /* squirreldoc (method)
    *
    * Pushes given instances values into SQL table row in database and executes result callback that receives given instances as argument.
    *
    * @static
    * @name		saveBatchAsync
    * @param	(array) models containing ORM.Model objects.
    * @param	(callback) result_callback result callback that receives current instance in argument.
    *
    */
    static function saveBatchAsync(models, result_callback = default_callback)
    {
        local query_string = ""
        foreach(model in models)
        {
            local class_ = model.getclass()
            local class_data = classes[class_]

            if (class_data.members.len() == class_data.primary_keys.len())
                continue

            model.beforeModelSave()
            query_string += model.save_query(class_)
        }


        ORM.engine.executeAsync(query_string, function(rows)
        {
            result_callback(models)

            foreach(model in models)
            {
                local class_ = model.getclass()
                local class_data = model.classes[class_]

                if (class_data.members.len() == class_data.primary_keys.len())
                    continue

                model.afterModelSave()
            }

        })
    }

    /* squirreldoc (method)
    *
    * Removes the SQL table row in database that corresponds to given instances.
    *
    * @static
    * @name		removeBatch
    * @param	(array) models containing ORM.Model objects. All models must be of the same class.
    * @return	(bool) `true` if remove was successful, otherwise `false`.
    *
    */
    static function removeBatch(models)
    {
        local query_count = ORM.Query(this)
            .count()
            .build()

        local query_string = ""
        query_string += query_count

        foreach(model in models)
        {
            local class_ = model.getclass()
            local class_data = classes[class_]

            local query_remove = ORM.Query(class_)
            .remove(model)
            .build()

            query_string += query_remove

            model.beforeModelDelete()
        }

        query_string += query_count

        local rows = ORM.engine.execute(query_string)
        local removed = rows[0].count != rows[1].count

        if(!removed)
            return false

        foreach(model in models)
        {
            local class_ = model.getclass()
            local class_data = classes[class_]

            delete class_data.cached_objects[model.getPrimaryKey()]
            model.afterModelDelete()
        }

        return true
    }


    /* squirreldoc (method)
    *
    * Removes the SQL table row in database that corresponds to given instances and executes result callback that receives success status as argument.
    *
    * @static
    * @name		removeBatchAsync
    * @param	(array) models containing ORM.Model objects. All models must be of the same class.
    * @param	(callback) result_callback result callback that receives success status in argument.
    *
    */
    static function removeBatchAsync(models, result_callback = default_callback)
    {
        local query_count = ORM.Query(this)
            .count()
            .build()

        local query_string = ""
        query_string += query_count

        foreach(model in models)
        {
            local class_ = model.getclass()
            local class_data = classes[class_]

            local query_remove = ORM.Query(class_)
            .remove(model)
            .build()

            query_string += query_remove

            model.beforeModelDelete()
        }

        query_string += query_count
        local self = this;

        ORM.engine.executeAsync(query_string, function(rows)
        {
            local removed = rows[0].count != rows[1].count

            if(!removed)
            {
                result_callback(false)
                return
            }

            foreach(model in models)
            {
                local class_ = model.getclass()
                local class_data = self.classes[class_]

                delete class_data.cached_objects[model.getPrimaryKey()]
                model.afterModelDelete()
            }

            result_callback(true)
        })
    }

    function _inherited(attributes)
    {
        if (!("table" in attributes))
            throw "(ORM.Model) class is missing 'table' attribute"

        classes[this] <- {
            attributes = attributes
            members = []
            member_attributes = {}
            primary_keys = []
            foreign_keys = {}
            auto_increment_column = null
            cached_objects = {}
        }

        table_classes[attributes.table] <- this
    }

    function _newmember(name, value, attributes, isstatic)
    {
        if (name in getdefaultdelegate("class"))
            throw "(ORM) cannot define field '" + name + "' because it's used by class delegate"

        this.rawnewmember(name, value, attributes, isstatic)

        if (isstatic)
            return

        if (!attributes)
            return

        local class_data = classes[this]
        local sq_type = typeof value

        // Add attribute from scheme if it doesn't exist already
        local scheme = "scheme" in attributes ? attributes.scheme : null
        if (scheme)
        {
            foreach (key, _ in scheme)
                attributes[key] <- key in attributes ? attributes[key] : scheme[key]

        }

        if (!("type" in attributes))
        {
            if (!(sq_type in ORM.engine.sq_to_sql_type))
                throw "(ORM) cannot map field type '" + name + "', you must pass explicit 'type' in field attributes"

            attributes.type <- ORM.engine.sq_to_sql_type[sq_type]
        }

        if ("not_null" in attributes && attributes.not_null != true)
            throw "(ORM) trying to set not_null=false on field '" + name + "', remove this attribute!"

        attributes.type = attributes.type.toupper()

        local attribute_has_primary_key = "primary_key" in attributes && attributes.primary_key
        if (attribute_has_primary_key)
        {
            class_data.primary_keys.push(name)

            if (class_data.primary_keys.len() > 1 && class_data.auto_increment_column)
                throw "(ORM) class can't have more than one primary_key while auto_increment attribute is being used"
        }

        if ("foreign_key" in attributes)
        {
            local foreign_key_len = attributes.foreign_key.len()
            if (foreign_key_len < 2 || foreign_key_len > 4)
                throw "(ORM) foreign_key attribute ill-formed in '" + name + "'"

            class_data.foreign_keys[name] <- attributes.foreign_key
        }

        local attribute_has_auto_increment = "auto_increment" in attributes && attributes.auto_increment
        if (attribute_has_auto_increment)
        {
            if (class_data.auto_increment_column)
                throw "(ORM) class can have only one field with auto_increment attribute"

            if (!(attribute_has_primary_key))
                throw "(ORM) auto_increment must be used in conjunction with primary_key"

            if (!ORM.engine.is_integer_type(attributes.type))
                throw "(ORM) only integer types support auto_increment"

            class_data.auto_increment_column = name
        }

        if (!("readonly" in attributes))
            attributes["readonly"] <- false

        class_data.members.push(name)
        class_data.member_attributes[name] <- attributes
    }
}
