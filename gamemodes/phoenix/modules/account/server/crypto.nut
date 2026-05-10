phoenix.account.Crypto <- {
	function makeSalt() {
		local seed = ""
		for (local i = 0; i < 8; ++i) {
			seed += rand().tostring()
			seed += "."
		}
		seed += clock().tostring()
		seed += "."
		seed += time().tostring()
		return sha256(seed)
	}

	function hash(password, salt) {
		return sha256(password + "/" + salt)
	}

	function verify(password, salt, expectedHash) {
		return expectedHash == hash(password, salt)
	}
}
