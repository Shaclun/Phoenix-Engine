/* squirreldoc (class)
*
* Class that allows you to properly evaluate SQL statement, can be useful if you need to leverage SQL engine specific behaviour.
* Keep in mind that using this class directly might break the compatibility with other supported SQL engines!
*
* @side       shared
* @name       ORM.Expression
*
*/
class ORM.Expression
{
	expression = ""

	/* squirreldoc (constructor)
    *
    * @param      (string) expression The raw SQL expression, can be used as field value in ORM.Model.
    *
    */
	constructor(expression)
	{
		this.expression = expression
	}

	function _typeof()
	{
		return "ORM.Expression"
	}
}