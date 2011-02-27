package jiglib.plugin.away3d4 
{
	import flash.geom.Vector3D;
	import flash.display.BitmapData;
	
	import away3d.arcane;
	import away3d.core.base.SubGeometry;
	import away3d.materials.MaterialBase;
	import away3d.primitives.PrimitiveBase;
	
	import jiglib.plugin.ITerrain;
	
	use namespace arcane;
	
	public class Away3D4Terrain extends PrimitiveBase implements ITerrain
	{
		
		//Min of coordinate horizontally;
		private var _minW:Number;
		
		//Min of coordinate vertically;
		private var _minH:Number;
		
		//Max of coordinate horizontally;
		private var _maxW:Number;
		
		//Max of coordinate vertically;
		private var _maxH:Number;
		
		//The horizontal length of each segment;
		private var _dw:Number;
		
		//The vertical length of each segment;
		private var _dh:Number;
		
		//the heights of all vertices
		private var _heights:Array;
		
		private var _segmentsW : uint;
		private var _segmentsH : uint;
		private var _width : Number;
		private var _height : Number;
		
		private var _maxHeight:Number;
		private var _heightMap:BitmapData;
		
		public function Away3D4Terrain(terrainHeightMap:BitmapData, material : MaterialBase, width : Number = 100, height : Number = 100, segw : uint = 1, segh : uint = 1, maxHeight:Number = 100)
		{
			super(material);
			
			_heightMap = terrainHeightMap;
			_width = width;
			_height = height;
			_segmentsW = segw;
			_segmentsH = segh;
			_maxHeight = maxHeight;
			
			var textureX:Number = width / 2;
			var textureY:Number = height / 2;
			
			_minW = -textureX;
			_minH = -textureY;
			_maxW = textureX;
			_maxH = textureY;
			_dw = width / segw;
			_dh = height / segh;
		}
		
		public function get minW():Number {
			return _minW;
		}
		public function get minH():Number {
			return _minH;
		}
		public function get maxW():Number {
			return _maxW;
		}
		public function get maxH():Number {
			return _maxH;
		}
		public function get dw():Number {
			return _dw;
		}
		public function get dh():Number {
			return _dh;
		}
		public function get sw():int {
			return _segmentsW;
		}
		public function get sh():int {
			return _segmentsH;
		}
		public function get heights():Array {
			return _heights;
		}
		public function get maxHeight():Number{
			return _maxHeight;
		}
		
		protected override function buildGeometry(target : SubGeometry) : void {
			
			_heights = [];
			for ( var ix:int = 0; ix <= _segmentsW; ix++ )
			{
				_heights[ix] = [];
				for ( var iy:int = 0; iy <= _segmentsH; iy++ )
				{
					_heights[ix][iy] = (_heightMap.getPixel((ix / (_segmentsW+1)) * _heightMap.width, (iy / (_segmentsH+1)) * _heightMap.height) & 0xFF);
					_heights[ix][iy] *= (_maxHeight / 255);
				}
			}
			
			var vertices : Vector.<Number>;
			var normals : Vector.<Number>;
			var tangents : Vector.<Number>;
			var indices : Vector.<uint>;
			var x : Number, z : Number;
			var numInds : uint;
			var base : uint;
			var tw : uint = _segmentsW+1;
			var numVerts : uint = (_segmentsH + 1) * tw;

			if (numVerts == target.numVertices) {
				vertices = target.vertexData;
				normals = target.vertexNormalData;
				tangents = target.vertexTangentData;
				indices = target.indexData
			}
			else {
				vertices = new Vector.<Number>(numVerts * 3, true);
				normals = new Vector.<Number>(numVerts * 3, true);
				tangents = new Vector.<Number>(numVerts * 3, true);
				indices = new Vector.<uint>(_segmentsH * _segmentsW * 6, true);
			}

			numVerts = 0;
			var normalVec:Vector3D;
			var tangentVec:Vector3D;
			for (iy = 0; iy <= _segmentsH; ++iy) {
				for (ix = 0; ix <= _segmentsW; ++ix) {
					x = (ix/_segmentsW-.5)*_width;
					z = (iy / _segmentsH - .5) * _height;
					
					normalVec = getNormalByIndex(ix, iy);
					tangentVec = normalVec.crossProduct(new Vector3D(1, 0, 0));

					vertices[numVerts] = x;
					normals[numVerts] = normalVec.x;
					tangents[numVerts++] = tangentVec.x;

					vertices[numVerts] = _heights[ix][iy];
					normals[numVerts] = normalVec.y;
					tangents[numVerts++] = tangentVec.y;

					vertices[numVerts] = z;
					normals[numVerts] = normalVec.z;
					tangents[numVerts++] = tangentVec.z;

					if (ix != _segmentsW && iy != _segmentsH) {
						base = ix + iy*tw;
						indices[numInds++] = base;
						indices[numInds++] = base + tw;
						indices[numInds++] = base + tw + 1;
						indices[numInds++] = base;
						indices[numInds++] = base + tw + 1;
						indices[numInds++] = base + 1;
					}
				}
			}

			target.updateVertexData(vertices);
			target.updateVertexNormalData(normals);
			target.updateVertexTangentData(tangents);
			target.updateIndexData(indices);
			
		}
		
		override protected function buildUVs(target : SubGeometry) : void
		{
			var uvs : Vector.<Number> = new Vector.<Number>();
			var numUvs : uint = (_segmentsH + 1) * (_segmentsW + 1) * 2;

			if (target.UVData && numUvs == target.UVData.length)
				uvs = target.UVData;
			else
				uvs = new Vector.<Number>(numUvs, true);

			numUvs = 0;
			for (var yi : uint = 0; yi <= _segmentsH; ++yi) {
				for (var xi : uint = 0; xi <= _segmentsW; ++xi) {
					uvs[numUvs++] = xi/_segmentsW;
					uvs[numUvs++] = 1 - yi/_segmentsH;
				}
			}

			target.updateUVData(uvs);
		}
		
		private function getNormalByIndex(i:int, j:int):Vector3D
		{
		   var i0:int = i - 1;
		   var i1:int = i + 1;
		   var j0:int = j - 1;
		   var j1:int = j + 1;
		   i0 = limiteInt(i0, 0, sw);
		   i1 = limiteInt(i1, 0, sw);
		   j0 = limiteInt(j0, 0, sh);
		   j1 = limiteInt(j1, 0, sh);

		   var dx:Number = (i1 - i0) * dw;
		   var dy:Number = (j1 - j0) * dh;
		   if (i0 == i1) dx = 1;
		   if (j0 == j1) dy = 1;
		   if (i0 == i1 && j0 == j1) return Vector3D.Y_AXIS;

		   var hFwd:Number = heights[i1][j];
		   var hBack:Number = heights[i0][j];
		   var hLeft:Number = heights[i][j1];
		   var hRight:Number = heights[i][j0];

		   var normal:Vector3D = new Vector3D(dx, hFwd - hBack, 0);
		   normal = new Vector3D(0, hLeft - hRight, dy).crossProduct(normal);
		   normal.normalize();
		   return normal;
		}
		
		private function limiteInt(num:int, min:int, max:int):int
		{
			var n:int = num;
			if (n < min)
				n = min;
			else if (n > max)
				n = max;
				
			return n;
		}
		
	}
}