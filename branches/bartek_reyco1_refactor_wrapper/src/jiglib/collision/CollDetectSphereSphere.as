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
	
	public class CollDetectSphereSphere extends CollDetectFunctor {
		
		public function CollDetectSphereSphere() {
			Name = "SphereSphere";
			Type0 = "SPHERE";
			Type1 = "SPHERE";
		}
		
		override public function CollDetect(info:CollDetectInfo, collArr:Array):void
		{
			var sphere0:JSphere = info.body0 as JSphere;
			var sphere1:JSphere = info.body1 as JSphere;
			
			var delta:JNumber3D = JNumber3D.sub(sphere0.CurrentState.Position, sphere1.CurrentState.Position);
			
			var dist:Number = delta.modulo;
			var radSum:Number = sphere0.Radius + sphere1.Radius;
			
			if (dist < radSum + JConfig.collToll)
			{
				var depth:Number = radSum - dist;
				delta.normalize();
				
				var worldPos:JNumber3D = JNumber3D.add(sphere1.CurrentState.Position, JNumber3D.multiply(delta, sphere1.Radius - 0.5 * depth));
				
				var collPts:Array = new Array();
				var cpInfo:CollPointInfo = new CollPointInfo();
				cpInfo.R0 = JNumber3D.sub(worldPos, sphere0.CurrentState.Position);
				cpInfo.R1 = JNumber3D.sub(worldPos, sphere1.CurrentState.Position);
				cpInfo.InitialPenetration = depth;
				collPts.push(cpInfo);
				
				var collInfo:CollisionInfo=new CollisionInfo();
			    collInfo.ObjInfo=info;
			    collInfo.DirToBody = delta;
			    collInfo.PointInfo = collPts;
				
				var mat:MaterialProperties = new MaterialProperties();
				mat.Restitution = Math.sqrt(sphere0.Material.Restitution * sphere1.Material.Restitution);
				mat.StaticFriction = Math.sqrt(sphere0.Material.StaticFriction * sphere1.Material.StaticFriction);
				mat.DynamicFriction = Math.sqrt(sphere0.Material.DynamicFriction * sphere1.Material.DynamicFriction);
				collInfo.Mat = mat;
				collArr.push(collInfo);
				
				info.body0.Collisions.push(collInfo);
			    info.body1.Collisions.push(collInfo);
			}
		}
		
	}
	
}
