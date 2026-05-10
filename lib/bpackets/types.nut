class BPacketBool {
    name = "bool"

    static function write(packet, value) {
        packet.writeBool(value)
    }

    static function read(packet) {
        return packet.readBool()
    }
}

class BPacketInt8 {
    name = "int8"

    static function write(packet, value) {
        packet.writeInt8(value)
    }

    static function read(packet) {
        return packet.readInt8()
    }
}

class BPacketUInt8 {
    name = "uint8"

    static function write(packet, value) {
        packet.writeUInt8(value)
    }

    static function read(packet) {
        return packet.readUInt8()
    }
}

class BPacketInt16 {
    name = "int16"

    static function write(packet, value) {
        packet.writeInt16(value)
    }

    static function read(packet) {
        return packet.readInt16()
    }
}

class BPacketUInt16 {
    name = "uint16"

    static function write(packet, value) {
        packet.writeUInt16(value)
    }

    static function read(packet) {
        return packet.readUInt16()
    }
}

class BPacketInt32 {
    name = "int32"

    static function write(packet, value) {
        packet.writeInt32(value)
    }

    static function read(packet) {
        return packet.readInt32()
    }
}

class BPacketUInt32 {
    name = "uint32"

    static function write(packet, value) {
        packet.writeUInt32(value)
    }

    static function read(packet) {
        return packet.readUInt32()
    }
}

class BPacketString {
    name = "string"

    static function write(packet, value) {
        packet.writeString(value)
    }

    static function read(packet) {
        return packet.readString()
    }
}

class BPacketFloat {
    name = "float"

    static function write(packet, value) {
        packet.writeFloat(value)
    }

    static function read(packet) {
        return packet.readFloat()
    }
}

enum BPacketAnyType
{
	NULL,
	BOOL,
	INT8,
	UINT8,
	INT16,
	UINT16,
	INT32,
	FLOAT,
	STRING,
	ARRAY,
	TABLE,
}

class BPacketAny {
	name = "any"

	static function write(packet, value) {
		switch (typeof(value)) {
			case "null":
				packet.writeUInt8(BPacketAnyType.NULL)
				break

			case "bool":
				packet.writeUInt8(BPacketAnyType.BOOL)
				packet.writeBool(value)
				break

			case "integer":
				if (value >= -128 && value <= 127) {
					packet.writeUInt8(BPacketAnyType.INT8)
					packet.writeInt8(value)
				}
				else if (value >= 0 && value <= 255) {
					packet.writeUInt8(BPacketAnyType.UINT8)
					packet.writeUInt8(value)
				}
				else if (value >= -32768 && value <= 32767) {
					packet.writeUInt8(BPacketAnyType.INT16)
					packet.writeInt16(value)
				}
				else if (value >= 0 && value <= 65535) {
					packet.writeUInt8(BPacketAnyType.UINT16)
					packet.writeUInt16(value)
				}
				else {
					packet.writeUInt8(BPacketAnyType.INT32)
					packet.writeInt32(value)
				}
				break

			case "float":
				packet.writeUInt8(BPacketAnyType.FLOAT)
				packet.writeFloat(value)
				break

			case "string":
				packet.writeUInt8(BPacketAnyType.STRING)
				packet.writeString(value)
				break

			case "array":
				packet.writeUInt8(BPacketAnyType.ARRAY)
				packet.writeUInt8(value.len())
				foreach (element in value) {
					BPacketAny.write(packet, element)
				}
				break

			case "table":
				packet.writeUInt8(BPacketAnyType.TABLE)
				packet.writeUInt8(value.len())
				foreach(key, element in value) {
					packet.writeString(key)
					BPacketAny.write(packet, element)
				}
				break

			default:
				packet.writeUInt8(BPacketAnyType.STRING)
				packet.writeString(value.tostring())
				break
		}
	}

	static function read(packet) {
		switch (packet.readUInt8()) {
			case BPacketAnyType.NULL:
				return null

			case BPacketAnyType.BOOL:
				return packet.readBool()

			case BPacketAnyType.INT8:
				return packet.readInt8()

			case BPacketAnyType.UINT8:
				return packet.readUInt8()

			case BPacketAnyType.INT16:
				return packet.readInt16()

			case BPacketAnyType.UINT16:
				return packet.readUInt16()

			case BPacketAnyType.INT32:
				return packet.readInt32()

			case BPacketAnyType.FLOAT:
				return packet.readFloat()

			case BPacketAnyType.STRING:
				return packet.readString()

			case BPacketAnyType.ARRAY:
				local count = packet.readUInt8()
				local tmp = []

				for (local i = 0; i < count; ++i) {
					tmp.push(BPacketAny.read(packet))
				}

				return tmp

			case BPacketAnyType.TABLE:
				local count = packet.readUInt8()
				local tmp = {}

				for (local i = 0; i < count; ++i) {
					local key = packet.readString()
					local value = BPacketAny.read(packet)

					tmp[key] <- value
				}

				return tmp
		}
	}
}

class BPacketArray {
    name = "array"
    _type = null

    constructor(type) {
        this._type = type
    }

    function write(packet, elements) {
        packet.writeUInt8(elements.len())
        foreach (element in elements) {
            this._type.write(packet, element)
        }
    }

    function read(packet) {
        local elements = []
        local count = packet.readUInt8()

        for (local i = 0; i < count; ++i) {
            elements.push(this._type.read(packet))
        }

        return elements
    }
}

class BPacketObject {
    name = "object"
    _scheme = null

    constructor(scheme) {
        this._scheme = scheme
    }

    function write(packet, elements) {
        foreach (index, type in this._scheme) {
            type.write(packet, elements[index])
        }
    }

    function read(packet) {
        local elements = {}

        foreach (index, type in this._scheme) {
            elements[index] <- type.read(packet)
        }

        return elements
    }
}

class BPacketTable {
	name = "table"
	_idx_type = null
	_value_type = null

	constructor(idx_type, value_type) {
        this._idx_type = idx_type
		this._value_type = value_type
    }

	function write(packet, elements) {
		packet.writeUInt8(elements.len())
		foreach (index, value in elements) {
			this._idx_type.write(packet, index)
			this._value_type.write(packet, value)
		}
    }

	function read(packet) {
        local elements = {}
        local count = packet.readUInt8()

        for (local i = 0; i < count; ++i) {
            elements[this._idx_type.read(packet)] <- this._value_type.read(packet)
        }

        return elements
    }
}