package com.derschmale.away3d.loading
{
	import away3d.loaders.parsers.MD5MeshParser;
	
	import flash.geom.Vector3D;
	
	/**
	 * AWDParser provides a parser for the md5mesh data type, providing the geometry of the md5 format.
	 *
	 * todo: optimize
	 */
	public class RotatedMD5MeshParser extends MD5MeshParser
	{
		/**
		 * Creates a new MD5MeshParser object.
		 * @param uri The url or id of the data or file to be parsed.
		 */
		public function RotatedMD5MeshParser()
		{
			super(new Vector3D(0, 1, 0), Math.PI*.5);
			//super(new Vector3D(0, 0, 1), Math.PI);
		}
		
		/**
		 * Indicates whether or not a given file extension is supported by the parser.
		 * @param extension The file extension of a potential file to be parsed.
		 * @return Whether or not the given file type is supported.
		 */
		public static function supportsType(extension : String) : Boolean
		{
			extension = extension.toLowerCase();
			return extension == "md5mesh";
		}
		
		/**
		 * Tests whether a data block can be parsed by the parser.
		 * @param data The data block to potentially be parsed.
		 * @return Whether or not the given data is supported.
		 */
		public static function supportsData(data : *) : Boolean
		{
			// todo: implement
			return false;
		}
	}
}