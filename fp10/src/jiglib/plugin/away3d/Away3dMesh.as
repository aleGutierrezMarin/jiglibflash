package jiglib.plugin.away3d {
	import flash.geom.Matrix3D;
	
	import jiglib.plugin.ISkin3D;
	import away3d.core.base.Mesh;
	import away3d.core.math.MatrixAway3D;
	
	/**
	 * @author bartekd
	 */
	public class Away3dMesh implements ISkin3D {
		
		private var _mesh:Mesh;

		public function Away3dMesh(do3d:Mesh) {
			this._mesh = do3d;
		}

		public function get transform():Matrix3D {
			var tr:Matrix3D = new Matrix3D();
			tr.rawData[0] = _mesh.transform.sxx; 
			tr.rawData[4] = _mesh.transform.sxy; 
			tr.rawData[8] = _mesh.transform.sxz; 
			tr.rawData[12] = _mesh.transform.tx;
			tr.rawData[1] = _mesh.transform.syx; 
			tr.rawData[5] = _mesh.transform.syy; 
			tr.rawData[9] = _mesh.transform.syz; 
			tr.rawData[13] = _mesh.transform.ty;
			tr.rawData[2] = _mesh.transform.szx; 
			tr.rawData[6] = _mesh.transform.szy; 
			tr.rawData[10] = _mesh.transform.szz; 
			tr.rawData[14] = _mesh.transform.tz;
			tr.rawData[3] = _mesh.transform.swx; 
			tr.rawData[7] = _mesh.transform.swy; 
			tr.rawData[11] = _mesh.transform.swz; 
			tr.rawData[15] = _mesh.transform.tw;
			
			return tr;
		}
		
		public function set transform(m:Matrix3D):void {
			var tr:MatrixAway3D = new MatrixAway3D();
			tr.sxx = m.rawData[0]; 
			tr.sxy = m.rawData[4]; 
			tr.sxz = m.rawData[8]; 
			tr.tx = m.rawData[12];
			tr.syx = m.rawData[1]; 
			tr.syy = m.rawData[5]; 
			tr.syz = m.rawData[9]; 
			tr.ty = m.rawData[13];
			tr.szx = m.rawData[2]; 
			tr.szy = m.rawData[6]; 
			tr.szz = m.rawData[10]; 
			tr.tz = m.rawData[14];
			tr.swx = m.rawData[3]; 
			tr.swy = m.rawData[7]; 
			tr.swz = m.rawData[11]; 
			tr.tw = m.rawData[15];
			
			var scale:MatrixAway3D = new MatrixAway3D();
			scale.scaleMatrix(_mesh.scaleX, _mesh.scaleY, _mesh.scaleZ);
			tr.multiply(tr, scale);
			
			_mesh.transform = tr;
		}
		
		public function get mesh():Mesh {
			return _mesh;
		}
	}
}
