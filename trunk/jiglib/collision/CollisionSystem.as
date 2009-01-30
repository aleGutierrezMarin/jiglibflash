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

	import jiglib.geometry.JSegment;
	import jiglib.math.*;
	import jiglib.physics.RigidBody;
	
	public class CollisionSystem {
		
		private var detectionFunctors:Array;
		private var collBody:Array;
		
		public function CollisionSystem() {
			collBody = new Array();
			detectionFunctors = new Array();
			detectionFunctors["BOX"] = new Array();
			detectionFunctors["BOX"]["BOX"] = new CollDetectBoxBox();
			detectionFunctors["BOX"]["SPHERE"] = new CollDetectSphereBox();
			detectionFunctors["BOX"]["PLANE"] = new CollDetectBoxPlane();
			detectionFunctors["SPHERE"] = new Array();
			detectionFunctors["SPHERE"]["BOX"] = new CollDetectSphereBox();
			detectionFunctors["SPHERE"]["SPHERE"] = new CollDetectSphereSphere();
			detectionFunctors["SPHERE"]["PLANE"] = new CollDetectSpherePlane();
			detectionFunctors["PLANE"] = new Array();
			detectionFunctors["PLANE"]["BOX"] = new CollDetectBoxPlane();
			detectionFunctors["PLANE"]["SPHERE"] = new CollDetectSpherePlane();
		}
		
		public function AddCollisionBody(body:RigidBody):void
		{
			if (!findBody(body))
			{
				collBody.push(body);
			}
		}
		public function RemoveCollisionBody(body:RigidBody):void
		{
			if (findBody(body))
			{
				collBody.splice(collBody.indexOf(body), 1);
			}
		}
		
		public function DetectCollisions(body:RigidBody, collArr:Array):void
		{
			if (!body.IsActive())
			{
				return;
			}
			var info:CollDetectInfo;
			var fu:CollDetectFunctor;
			 
			for (var i:String in collBody)
			{ 
				if (body != collBody[i] && detectionFunctors[body.Type][collBody[i].Type] != undefined)
				{
					info = new CollDetectInfo();
					info.body0 = body;
					info.body1 = collBody[i];
					fu = detectionFunctors[info.body0.Type][info.body1.Type];
					fu.CollDetect(info, collArr);
				}
			}
		}
		public function DetectAllCollisions(bodies:Array, collArr:Array):void
		{
			var info:CollDetectInfo;
			var fu:CollDetectFunctor;
			for (var i:String in bodies)
			{
				for (var j:String in collBody)
				{
					if (bodies[i] == collBody[j])
					{
						continue;
					}
					
					if (collBody[j].IsActive() && bodies[i].ID > collBody[j].ID)
					{
						continue;
					}
					
					if (detectionFunctors[bodies[i].Type][collBody[j].Type] != undefined)
					{
						info = new CollDetectInfo();
			        	info.body0 = bodies[i];
						info.body1 = collBody[j];
						fu = detectionFunctors[info.body0.Type][info.body1.Type];
					    fu.CollDetect(info, collArr);
					}
				}
			}
		}
		
		public function SegmentIntersect(out:Object, seg:JSegment, ownerBody:RigidBody):Boolean
		{
			out.fracOut = JNumber3D.NUM_HUGE;
			out.posOut = new JNumber3D();
			out.normalOut = new JNumber3D();
			
			var obj:Object = new Object();
			for (var i:String in collBody)
			{
				if (collBody[i] != ownerBody && SegmentBounding(seg, collBody[i]))
				{
					if (collBody[i].SegmentIntersect(obj, seg))
					{
						if (obj.fracOut < out.fracOut)
						{
							out.posOut = obj.posOut;
							out.normalOut = obj.normalOut;
							out.fracOut = obj.fracOut;
							out.bodyOut = collBody[i];
						}
					}
				}
			}
			 
			if (out.fracOut > 1)
			{
				return false;
			}
			if (out.fracOut < 0)
			{
				out.fracOut = 0;
			}
			else if (out.fracOut > 1)
			{
				out.fracOut = 1;
			}
			return true;
		}
		 
		public function SegmentBounding(seg:JSegment,obj:RigidBody):Boolean
		{
			var pos:JNumber3D = seg.GetPoint(0.5);
			var r:Number = seg.Delta.modulo / 2;
			
			if (obj.Type != "PLANE")
			{
				var num1:Number = JNumber3D.sub(pos, obj.CurrentState.Position).modulo;
				var num2:Number = r + obj.BoundingSphere;
				if (num1 <= num2)
				{
					return true;
				}
				else
				{
					return false;
				}
			}
			else
			{
				return true;
			}
		}
		 
		private function findBody(body:RigidBody):Boolean
		{
			for (var i:String in collBody)
			{
				if (body == collBody[i])
				{
					return true;
				}
			}
			return false;
		}
	}
	
}
