package jiglib.plugin {
	import jiglib.math.JMatrix3D;	
	
	/**
	 * @author bartekd
	 */
	public interface ISkin3D {
		
		function get transform():JMatrix3D;
		
		function set transform(m:JMatrix3D):void;
	}
}
