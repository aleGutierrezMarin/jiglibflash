package jiglib.plugin.five3d {
	import flash.geom.Vector3D;
	import jiglib.plugin.ISkin3D;
	import flash.geom.Matrix3D;
	
	import five3D.display.Sprite3D;
	import five3D.geom.Matrix3D;

	/**
	 * @author Devin Reimer (blog.almostlogical.com), based on class Pv3dMesh written by bartekd
	 * */
	public class FIVe3DMesh implements ISkin3D
	{	
		private var sprite3D:Sprite3D;
		
		public function FIVe3DMesh(sprite3D:Sprite3D) {
			this.sprite3D = sprite3D;
		}
		
		public function get transform():flash.geom.Matrix3D
		{
			var tr:flash.geom.Matrix3D = new flash.geom.Matrix3D();
		
			tr.rawData[0] = sprite3D.matrix.a;
			tr.rawData[4] = -sprite3D.matrix.b; //-
			tr.rawData[8] = sprite3D.matrix.c; 
			tr.rawData[1] = -sprite3D.matrix.d; //-
			tr.rawData[5] = sprite3D.matrix.e;
			tr.rawData[9] = -sprite3D.matrix.f; //-
			tr.rawData[2] = sprite3D.matrix.g; 
			tr.rawData[6]= -sprite3D.matrix.h; //-
			tr.rawData[10] = sprite3D.matrix.i;
			
			tr.rawData[12] = sprite3D.matrix.tx;
			tr.rawData[13] = -sprite3D.matrix.ty; //-
			tr.rawData[14] = sprite3D.matrix.tz;
			
			return tr;
		}
		
		
		public function set transform(m:flash.geom.Matrix3D):void {
			var tr:five3D.geom.Matrix3D = new five3D.geom.Matrix3D();
			
			tr.a = m.rawData[0];
			tr.b = -m.rawData[4]; //-
			tr.c = m.rawData[8]; 
			tr.d = -m.rawData[1]; //-
			tr.e = m.rawData[5];
			tr.f = -m.rawData[9]; //-
			tr.g = m.rawData[2]; 
			tr.h = -m.rawData[6]; //-
			tr.i = m.rawData[10];
			
			tr.tx = m.rawData[12];
			tr.ty = -m.rawData[13]; //-
			tr.tz = m.rawData[14];
	
			sprite3D.matrix = tr;	
		}
		
		
		public function get mesh():Sprite3D {
			return sprite3D;
		}
		
	}
}
