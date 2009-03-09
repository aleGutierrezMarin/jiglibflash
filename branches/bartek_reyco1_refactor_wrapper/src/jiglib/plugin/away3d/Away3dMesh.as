package jiglib.plugin.away3d {
	import jiglib.plugin.ISkin3D;
	import away3d.core.base.Mesh;
	import away3d.core.math.Matrix3D;
	
	import jiglib.math.JMatrix3D;		

	/**
	 * @author bartekd
	 */
	public class Away3dMesh implements ISkin3D {
		
		private var mesh:Mesh;

		public function Away3dMesh(do3d:Mesh) {
			this.mesh = do3d;
		}

		public function get transform():JMatrix3D {
			var tr:JMatrix3D = new JMatrix3D();
			tr.n11 = mesh.transform.sxx; 
			tr.n12 = mesh.transform.sxy; 
			tr.n13 = mesh.transform.sxz; 
			tr.n14 = mesh.transform.tx;
			tr.n21 = mesh.transform.syx; 
			tr.n22 = mesh.transform.syy; 
			tr.n23 = mesh.transform.syz; 
			tr.n24 = mesh.transform.ty;
			tr.n31 = mesh.transform.szx; 
			tr.n32 = mesh.transform.szy; 
			tr.n33 = mesh.transform.szz; 
			tr.n34 = mesh.transform.tz;
			tr.n41 = mesh.transform.swx; 
			tr.n42 = mesh.transform.swy; 
			tr.n43 = mesh.transform.swz; 
			tr.n44 = mesh.transform.tw;
			 
			return tr;
		}
		
		public function set transform(m:JMatrix3D):void {
			var tr:Matrix3D = new Matrix3D();
			tr.sxx = m.n11; 
			tr.sxy = m.n12; 
			tr.sxz = m.n13; 
			tr.tx = m.n14;
			tr.syx = m.n21; 
			tr.syy = m.n22; 
			tr.syz = m.n23; 
			tr.ty = m.n24;
			tr.szx = m.n31; 
			tr.szy = m.n32; 
			tr.szz = m.n33; 
			tr.tz = m.n34;
			tr.swx = m.n41; 
			tr.swy = m.n42; 
			tr.swz = m.n43; 
			tr.tw = m.n44;
			mesh.transform = tr;
		}
	}
}
