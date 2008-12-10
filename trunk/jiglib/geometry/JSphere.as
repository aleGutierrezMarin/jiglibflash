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
	import org.papervision3d.core.proto.MaterialObject3D;
	import org.papervision3d.materials.utils.MaterialsList;
	import org.papervision3d.objects.primitives.Sphere;
	
	public class JSphere extends JObject3D {
		
		private var _radius:Number;
		
		public function JSphere(material:MaterialObject3D=null, radius:Number=100, segmentsW:int=8, segmentsH:int=6,skin:Boolean=true) {
			this.Type = "SPHERE";
			
			if (skin)
			{
		    	this.Skin = new Sphere(material, radius, segmentsW, segmentsH);
			}
			
			_radius = radius;
			
			this.BoundingSphere = _radius;
		}
		 
		public function get Radius():Number
		{
			return _radius;
		}
		 
		public function SegmentIntersect(out:Object, seg:JSegment):Boolean
		{
			out.posOut = new JNumber3D();
			
			var frac:Number = 0;
			var r:JNumber3D = seg.Delta;
			var s:JNumber3D = JNumber3D.sub(seg.Origin, this.Position);
			
			var radiusSq:Number = _radius * _radius;
			var rSq:Number = r.modulo2;
			if (rSq < radiusSq)
			{
				out.posOut = seg.Origin.clone();
				return true;
			}
			
			var sDotr:Number = JNumber3D.dot(s, r);
			var sSq:Number = s.modulo2;
			var sigma:Number = sDotr * sDotr - rSq * (sSq - radiusSq);
			if (sigma < 0)
			{
				return false;
			}
			var sigmaSqrt:Number = Math.sqrt(sigma);
			var lambda1:Number = ( -sDotr - sigmaSqrt) / rSq;
			var lambda2:Number = ( -sDotr + sigmaSqrt) / rSq;
			if (lambda1 > 1 || lambda2 < 0)
			{
				return false;
			}
			frac = Math.max(lambda1, 0);
			out.posOut = seg.GetPoint(frac);
			return true;
		}
		
		public function GetMassProperties(mass:Number):JMatrix3D
		{
			var inertiaTensor:JMatrix3D = new JMatrix3D();
			 
			var Ixx:Number = 0.4 * mass * _radius * _radius;
			inertiaTensor.n11 = Ixx;
			inertiaTensor.n22 = Ixx;
			inertiaTensor.n33 = Ixx;
			 
			return inertiaTensor;
		}
	}
	
}
