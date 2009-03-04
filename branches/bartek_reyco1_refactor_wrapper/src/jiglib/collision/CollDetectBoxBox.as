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

package jiglib.collision {
	import jiglib.cof.JConfig;
	import jiglib.geometry.*;
	import jiglib.math.*;
	import jiglib.physics.MaterialProperties;	

	public class CollDetectBoxBox extends CollDetectFunctor {

		public function CollDetectBoxBox() {
			name = "BoxBox";
			type0 = "BOX";
			type1 = "BOX";
		}

		private function disjoint(out:Object, axis:JNumber3D, box0:JBox, box1:JBox):Boolean {
			var obj0:Object = box0.getSpan(axis);
			var obj1:Object = box1.getSpan(axis);
			 
			if (obj0.min > (obj1.max + JConfig.collToll + JNumber3D.NUM_TINY) || obj1.min > (obj0.max + JConfig.collToll + JNumber3D.NUM_TINY)) {
				out.flag = true;
				return true;
			}
			if ((obj0.max > obj1.max) && (obj1.min > obj0.min)) {
				out.depth = Math.min(obj0.max - obj1.min, obj1.max - obj0.min);
			}
            else if ((obj1.max > obj0.max) && (obj0.min > obj1.min)) {
				out.depth = Math.min(obj1.max - obj0.min, obj0.max - obj1.min);
			} else {
				out.depth = Math.min(obj0.max, obj1.max);
				out.depth -= Math.max(obj0.min, obj1.min);
			}
			out.flag = false;
			return false;
		}

		private function addPoint(contactPoint:Array, pt:JNumber3D, combinationDistanceSq:Number):Boolean {
			for (var i:String in contactPoint) {
				if (JNumber3D.sub(contactPoint[i].pos, pt).modulo2 < combinationDistanceSq) {
					contactPoint[i].pos = JNumber3D.divide(JNumber3D.add(contactPoint[i].pos, pt), 2);
					contactPoint[i].count += 1;
					return false;
				}
			}
			contactPoint.push({ pos:pt, count:1 });
			return true;
		}

		private function getBox2BoxEdgesIntersectionPoints(contactPoint:Array,box0:JBox,box1:JBox,combinationDistanceSq:Number):Number {
			var num:Number = 0;
			var seg:JSegment;
			var boxPts:Array = box1.getCornerPoints();
			var boxEdges:Array = box1.edges;
			var outObj:Object;
			for (var i:String in boxEdges) {
				outObj = new Object();
				seg = new JSegment(boxPts[boxEdges[i].ind0], JNumber3D.sub(boxPts[boxEdges[i].ind1], boxPts[boxEdges[i].ind0]));
				if(box0.segmentIntersect(outObj, seg)) {
					if (addPoint(contactPoint, outObj.posOut, combinationDistanceSq)) {
						num += 1;
					}
				}
			}
			return num;
		}

		
		private function getBoxBoxIntersectionPoints(contactPoint:Array, box0:JBox, box1:JBox,
		                                             combinationDistance:Number):uint {
			getBox2BoxEdgesIntersectionPoints(contactPoint, box0, box1, combinationDistance * combinationDistance);
			getBox2BoxEdgesIntersectionPoints(contactPoint, box1, box0, combinationDistance * combinationDistance);
			return contactPoint.length;
		}

		override public function collDetect(info:CollDetectInfo, collArr:Array):void {
			var box0:JBox = info.body0 as JBox;
			var box1:JBox = info.body1 as JBox;
			 
			if (!box0.hitTestObject3D(box1)) {
				return;
			}
			 
			var dirs0Arr:Array = box0.currentState.orientation.getCols();
			var dirs1Arr:Array = box1.currentState.orientation.getCols();
			 
			var axes:Array = new Array(dirs0Arr[0], dirs0Arr[1], dirs0Arr[2], dirs1Arr[0], dirs1Arr[1], dirs1Arr[2], JNumber3D.cross(dirs1Arr[0], dirs0Arr[0]), JNumber3D.cross(dirs1Arr[0], dirs0Arr[1]), JNumber3D.cross(dirs1Arr[0], dirs0Arr[2]), JNumber3D.cross(dirs1Arr[1], dirs0Arr[0]), JNumber3D.cross(dirs1Arr[1], dirs0Arr[1]), JNumber3D.cross(dirs1Arr[1], dirs0Arr[2]), JNumber3D.cross(dirs1Arr[2], dirs0Arr[0]), JNumber3D.cross(dirs1Arr[2], dirs0Arr[1]), JNumber3D.cross(dirs1Arr[2], dirs0Arr[2]));
									   
			var l2:Number;
			var overlapDepths:Array = new Array();
			for (var i:uint = 0;i < axes.length; i++ ) {
				overlapDepths[i] = new Object();
				overlapDepths[i].flag = false;
				overlapDepths[i].depth = JNumber3D.NUM_HUGE;
				l2 = axes[i].modulo2;
				if (l2 < JNumber3D.NUM_TINY) {
					continue;
				}
				var ax:JNumber3D = axes[i].clone();
				ax.normalize();
				if (disjoint(overlapDepths[i], ax, box0, box1)) {
					return;
				}
			}
			 
			var minDepth:Number = JNumber3D.NUM_HUGE;
			var minAxis:int = -1;
			
			for (i = 0;i < axes.length; i++ ) {
				l2 = axes[i].modulo2;
				if (l2 < JNumber3D.NUM_TINY) {
					continue;
				}
				
				if (overlapDepths[i].depth < minDepth) {
					minDepth = overlapDepths[i].depth;
					minAxis = i;
				}
			}
			if (minAxis == -1) {
				return;
			}
			var N:JNumber3D = axes[minAxis].clone();
			if (JNumber3D.dot(JNumber3D.sub(box1.currentState.position, box0.currentState.position), N) > 0) {
				N = JNumber3D.multiply(N, -1);
			}
			var combinationDist:Number = 0.5 * Math.min(Math.min(box0.sideLengths.x, box0.sideLengths.y, box0.sideLengths.z), Math.min(box1.sideLengths.x, box1.sideLengths.y, box1.sideLengths.z));
			var contactPoint:Array = new Array();
			if (minDepth > -JNumber3D.NUM_TINY) {
				getBoxBoxIntersectionPoints(contactPoint, box0, box1, combinationDist);
			}
			var collPts:Array = new Array();

			if (contactPoint.length > 0) {
				var depth:Number = 0;
				var cpInfo:CollPointInfo;
				for (i = 0;i < contactPoint.length; i++ ) {
					depth = minDepth;
					 
					cpInfo = new CollPointInfo();
					cpInfo.r0 = JNumber3D.sub(contactPoint[i].pos, box0.currentState.position);
					cpInfo.r1 = JNumber3D.sub(contactPoint[i].pos, box1.currentState.position);
					cpInfo.position = contactPoint[i].pos;
					cpInfo.initialPenetration = depth;
					collPts.push(cpInfo);
				}
			}
			var collInfo:CollisionInfo = new CollisionInfo();
			collInfo.ObjInfo = info;
			collInfo.DirToBody = N;
			collInfo.PointInfo = collPts;
			 
			var mat:MaterialProperties = new MaterialProperties();
			mat.restitution = Math.sqrt(box0.material.restitution * box1.material.restitution);
			mat.staticFriction = Math.sqrt(box0.material.staticFriction * box1.material.staticFriction);
			mat.dynamicFriction = Math.sqrt(box0.material.dynamicFriction * box1.material.dynamicFriction);
			collInfo.Mat = mat;
			collArr.push(collInfo);
			 
			info.body0.collisions.push(collInfo);
			info.body1.collisions.push(collInfo);
		}
	}
}