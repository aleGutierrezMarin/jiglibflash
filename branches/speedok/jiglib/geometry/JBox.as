/*
Copyright (c) 2007 Danny Chapman 
http://www.rowlhouse.co.uk

This software is provided 'as-is', without any express or implied
warranty. In no event will the authors be held liable for any damages
arising from the use of this software.
Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it
freely, subject to the following restrictions:
1. The origin of this software must not be misrepresented; you must not
claim that you wrote the original software. If you use this software
in a product, an acknowledgment in the product documentation would be
appreciated but is not required.
2. Altered source versions must be plainly marked as such, and must not be
misrepresented as being the original software.
3. This notice may not be removed or altered from any source
distribution.
*/

/**
* @author Muzer(muzerly@gmail.com)
* @link http://code.google.com/p/jiglibflash
*/

package jiglib.geometry {

	import jiglib.math.*;
	import jiglib.physics.RigidBody;
	import org.papervision3d.objects.DisplayObject3D;
	
	public class JBox extends RigidBody {
		
		public var name:String;
		private var _sideLengths:JNumber3D;
		private var _points:Array;
		private var _edges:Array=new Array({ ind0:0, ind1:1 }, { ind0:3, ind1:1 }, { ind0:2, ind1:3 },
			                             { ind0:2, ind1:0 }, { ind0:4, ind1:5 }, { ind0:5, ind1:7 },
							             { ind0:6, ind1:7 }, { ind0:4, ind1:6 }, { ind0:7, ind1:1 },
							             { ind0:5, ind1:3 }, { ind0:4, ind1:2 }, { ind0:6, ind1:0 });
										 
		 
		public function JBox(skin:DisplayObject3D, mov:Boolean = true, width:Number = 500, depth:Number = 500, height:Number = 500) {
			
			super(skin, mov);
			_type = "BOX";
			
			_sideLengths = new JNumber3D(width, height, depth);
			_boundingSphere = 0.5 * _sideLengths.modulo;
			initPoint();
			this.setMass(1);
		}
		private function initPoint():void
		{
			var halfSide:JNumber3D = GetHalfSideLengths();
			_points = new Array();
			_points[0] = new JNumber3D(halfSide.x, -halfSide.y, halfSide.z);
			_points[1] = new JNumber3D(halfSide.x, halfSide.y, halfSide.z);
			_points[2] = new JNumber3D(-halfSide.x, -halfSide.y, halfSide.z);
			_points[3] = new JNumber3D(-halfSide.x, halfSide.y, halfSide.z);
			_points[4] = new JNumber3D(-halfSide.x, -halfSide.y, -halfSide.z);
			_points[5] = new JNumber3D(-halfSide.x, halfSide.y, -halfSide.z);
			_points[6] = new JNumber3D(halfSide.x, -halfSide.y, -halfSide.z);
			_points[7] = new JNumber3D(halfSide.x, halfSide.y, -halfSide.z);
		}
		 
		public function set SideLengths(size:JNumber3D):void
		{
			_sideLengths = size.clone();
			_boundingSphere = 0.5 * _sideLengths.modulo;
			initPoint();
			this.setMass(this.Mass);
			this.SetActive();
		}
		
		public function get SideLengths():JNumber3D
		{
			return _sideLengths;
		}
		public function get Edges():Array
		{
			return _edges;
		}
		
		public function GetVolume():Number
		{
			return (SideLengths.x * SideLengths.y * SideLengths.z);
		}
		public function GetSurfaceArea():Number
		{
			return 2 * (SideLengths.x * SideLengths.y + SideLengths.x * SideLengths.z + SideLengths.y * SideLengths.z);
		}
		public function GetHalfSideLengths():JNumber3D
		{
			return JNumber3D.multiply(_sideLengths, 0.5);
		}
		
		public function GetSpan(axis:JNumber3D):Object
		{
			var obj:Object = new Object();
			var s:Number = Math.abs(JNumber3D.dot(axis, CurrentState.Orientation.getCols()[0])) * (0.5 * SideLengths.x);
			var u:Number = Math.abs(JNumber3D.dot(axis, CurrentState.Orientation.getCols()[1])) * (0.5 * SideLengths.y);
			var d:Number = Math.abs(JNumber3D.dot(axis, CurrentState.Orientation.getCols()[2])) * (0.5 * SideLengths.z);
			var r:Number = s + u + d;
			var p:Number = JNumber3D.dot(CurrentState.Position, axis);
			obj.min = p - r;
			obj.max = p + r;
			 
			return obj;
		}
		
		public function GetCornerPoints():Array
		{
			var vertex:JNumber3D;
			var arr:Array = new Array();
			for (var i:String in _points)
			{
				vertex = new JNumber3D(_points[i].x, _points[i].y, _points[i].z);
				JMatrix3D.multiplyVector(getTransform(), vertex);
				arr.push(vertex);
			}
			 
			return arr;
		}
		 
		public function GetSqDistanceToPoint(closestBoxPoint:Object, point:JNumber3D):Number
		{
			closestBoxPoint.pos = JNumber3D.sub(point, CurrentState.Position);
			JMatrix3D.multiplyVector(JMatrix3D.Transpose(CurrentState.Orientation), closestBoxPoint.pos);
			
			var delta:Number = 0;
			var sqDistance:Number = 0;
			var halfSideLengths:JNumber3D = GetHalfSideLengths();
			
			if ( closestBoxPoint.pos.x < -halfSideLengths.x )
            {
				delta = closestBoxPoint.pos.x + halfSideLengths.x;
                sqDistance += (delta * delta);
                closestBoxPoint.pos.x = -halfSideLengths.x;
            }
            else if ( closestBoxPoint.pos.x > halfSideLengths.x )
            {
                delta = closestBoxPoint.pos.x - halfSideLengths.x;
                sqDistance += (delta * delta);
                closestBoxPoint.pos.x = halfSideLengths.x;
            }
			 
            if ( closestBoxPoint.pos.y < -halfSideLengths.y )
            {
                delta = closestBoxPoint.pos.y + halfSideLengths.y;
                sqDistance += (delta * delta);
                closestBoxPoint.pos.y = -halfSideLengths.y;
            }
            else if ( closestBoxPoint.pos.y > halfSideLengths.y )
            {
                delta = closestBoxPoint.pos.y - halfSideLengths.y;
                sqDistance += (delta * delta);
                closestBoxPoint.pos.y = halfSideLengths.y;
            }
             
            if ( closestBoxPoint.pos.z < -halfSideLengths.z )
            {
                delta = closestBoxPoint.pos.z + halfSideLengths.z;
                sqDistance += (delta * delta);
                closestBoxPoint.pos.z = -halfSideLengths.z;
            }
            else if ( closestBoxPoint.pos.z > halfSideLengths.z )
            {
                delta = (closestBoxPoint.pos.z - halfSideLengths.z);
                sqDistance += (delta * delta);
                closestBoxPoint.pos.z = halfSideLengths.z;
            }
			JMatrix3D.multiplyVector(CurrentState.Orientation, closestBoxPoint.pos);
			closestBoxPoint.pos = JNumber3D.add(CurrentState.Position, closestBoxPoint.pos);
            return sqDistance;
		}
		
		public function GetDistanceToPoint(closestBoxPoint:Object, point:JNumber3D):Number
		{
			return Math.sqrt(GetSqDistanceToPoint(closestBoxPoint, point));
		}
		
		public function PointIntersect(pos:JNumber3D):Boolean
		{
			var p:JNumber3D=JNumber3D.sub(pos,CurrentState.Position);
			var h:JNumber3D = JNumber3D.multiply(SideLengths, 0.5);
			var dirVec:JNumber3D;
			for(var dir:int;dir<3;dir++)
			{
				dirVec = CurrentState.Orientation.getCols()[dir].clone();
				dirVec.normalize();
				if(Math.abs(JNumber3D.dot(dirVec,p))>h.toArray()[dir]+JNumber3D.NUM_TINY)
				{
					return false;
				}
			}
			return true;
		}
		 
		override public function SegmentIntersect(out:Object,seg:JSegment):Boolean
		{
			out.fracOut = 0;
			out.posOut = new JNumber3D();
			out.normalOut = new JNumber3D();
			
			var frac:Number = JNumber3D.NUM_HUGE;
			var min:Number = -JNumber3D.NUM_HUGE;
			var max:Number = JNumber3D.NUM_HUGE;
			var dirMin:Number = 0;
			var dirMax:Number = 0;
			var dir:Number = 0;
			var p:JNumber3D = JNumber3D.sub(CurrentState.Position, seg.Origin);
			var h:JNumber3D = JNumber3D.multiply(SideLengths, 0.5);
			
			var tempV:JNumber3D;
			var e:Number;
			var f:Number;
			var t:Number;
			var t1:Number;
			var t2:Number;
			for (dir = 0; dir < 3; dir++)
			{
				e = JNumber3D.dot(CurrentState.Orientation.getCols()[dir], p);
				f = JNumber3D.dot(CurrentState.Orientation.getCols()[dir], seg.Delta);
				if (Math.abs(f) > JNumber3D.NUM_TINY)
				{
					t1 = (e + h.toArray()[dir]) / f;
					t2 = (e - h.toArray()[dir]) / f;
					if (t1 > t2)
					{
						t = t1;
						t1 = t2;
						t2 = t;
					}
					if (t1 > min)
					{
						min = t1;
                        dirMin = dir;
					}
					if (t2 < max) 
                    {
                        max = t2;
                        dirMax = dir;
                    }
					if (min > max) return false;
                    if (max < 0) return false;
				}
				else if ( -e - h.toArray()[dir] > 0 || -e + h.toArray()[dir] < 0)
				{
					return false;
				}
			}
			
			if (min > 0)
            {
                dir = dirMin;
                frac = min;
            }
			else
			{
				dir = dirMax;
                frac = max;
			}
			if (frac < 0) frac = 0;
			if (frac > 1) frac = 1;
			if(frac>0.999999)
			{
				return false;
			}
			out.fracOut = frac;
			out.posOut = seg.GetPoint(frac);
			if (JNumber3D.dot(CurrentState.Orientation.getCols()[dir], seg.Delta) < 0)
			{
				out.normalOut = JNumber3D.multiply(CurrentState.Orientation.getCols()[dir], -1);
			}
			else
			{
				out.normalOut = CurrentState.Orientation.getCols()[dir];
			}
			return true;
		}
		
		override public function GetInertiaProperties(mass:Number):JMatrix3D
		{
			var inertiaTensor:JMatrix3D = new JMatrix3D();
			inertiaTensor.n11 = (mass / 12) * (SideLengths.y * SideLengths.y + SideLengths.z * SideLengths.z);
			inertiaTensor.n22 = (mass / 12) * (SideLengths.x * SideLengths.x + SideLengths.z * SideLengths.z);
			inertiaTensor.n33 = (mass / 12) * (SideLengths.x * SideLengths.x + SideLengths.y * SideLengths.y);
			return inertiaTensor;
		}
		
	}
	
}
