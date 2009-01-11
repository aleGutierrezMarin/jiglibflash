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
	import jiglib.physics.RigidBody;
	import jiglib.physics.MaterialProperties;
	
	public class CollDetectBoxPlane extends CollDetectFunctor {
		
		public function CollDetectBoxPlane() {
			Name = "BoxPlane";
			Type0 = "BOX";
			Type1 = "PLANE";
		}
		
		override public function CollDetect(info:CollDetectInfo, collArr:Array):void
		{
			var tempBody:RigidBody;
			if(info.body0.Type=="PLANE")
			{
				tempBody=info.body0;
				info.body0=info.body1;
				info.body1=tempBody;
			}
			
			var box:JBox = info.body0 as JBox;
			var plane:JPlane = info.body1 as JPlane;
			
			var centreDist:Number = plane.PointPlaneDistance(box.CurrentState.Position);
			if (centreDist > box.BoundingSphere + JConfig.collToll)
			{
				return;
			}
			
			var newPts:Array=box.GetCornerPoints();
			var collPts:Array = new Array();
			var cpInfo:CollPointInfo;
			var pt:JNumber3D;
			var depth:Number;
			for(var i:String in newPts)
			{
				pt=newPts[i];
				depth=-1*plane.PointPlaneDistance(pt);
				if(depth>-JConfig.collToll)
				{
					cpInfo=new CollPointInfo();
					cpInfo.R0 = JNumber3D.sub(pt, box.CurrentState.Position);
					cpInfo.R1 = JNumber3D.sub(pt, plane.CurrentState.Position);
					cpInfo.InitialPenetration = depth;
					collPts.push(cpInfo);
				}
			}
			if(collPts.length>0)
			{
				var collInfo:CollisionInfo=new CollisionInfo();
			    collInfo.ObjInfo=info;
			    collInfo.DirToBody = plane.Normal;
			    collInfo.PointInfo = collPts;
				
				var mat:MaterialProperties = new MaterialProperties();
				mat.Restitution = Math.sqrt(box.Material.Restitution * plane.Material.Restitution);
				mat.StaticFriction = Math.sqrt(box.Material.StaticFriction * plane.Material.StaticFriction);
				mat.DynamicFriction = Math.sqrt(box.Material.DynamicFriction * plane.Material.DynamicFriction);
				collInfo.Mat = mat;
				collArr.push(collInfo);
				info.body0.Collisions.push(collInfo);
			    info.body1.Collisions.push(collInfo);
			}
		}
	}
	
}
