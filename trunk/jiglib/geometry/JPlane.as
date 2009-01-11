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
	
	public class JPlane extends RigidBody{
		
		private var _normal:JNumber3D;
		private var _distance:Number;
		
		public function JPlane(skin:DisplayObject3D) {
			
			super(skin, false);
			_type = "PLANE";
			
			_normal = new JNumber3D(0, 0, -1);
			_distance = 0;
		}
		
		public function get Normal():JNumber3D
		{
			return _normal;
		}
		
		public function get Distance():Number
		{
			return _distance;
		}
		 
		public function PointPlaneDistance(pt:JNumber3D):Number
		{
			return JNumber3D.dot(_normal, pt) - _distance;
		}
		
		override public function MoveTo(pos:JNumber3D, orientation:JMatrix3D):void
		{	
			pos.copyTo(CurrentState.Position);
			SetOrientation(orientation);
			CurrentState.LinVelocity = JNumber3D.ZERO;
			CurrentState.RotVelocity = JNumber3D.ZERO;
			CopyCurrentStateToOld();
			
			_normal = new JNumber3D(0, 0, -1);
			JMatrix3D.multiplyVector(orientation, _normal);
			_distance = JNumber3D.dot(pos, _normal);
		}
	}
	
}
