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
	import jiglib.physics.MaterialProperties;
	import org.papervision3d.core.math.*;
	import org.papervision3d.objects.DisplayObject3D;
	
	public class JObject3D {
		
		public var Type:String = "Object3D";
		public var Position:JNumber3D;
		public var Orientation:JMatrix3D;
		public var Skin:DisplayObject3D;
		public var Material:MaterialProperties;
		public var BoundingSphere:Number;
		
		public function JObject3D()
		{
			BoundingSphere = 0;
			Material = new MaterialProperties();
		}
		
		public function getTransform():JMatrix3D
		{
			var tr:JMatrix3D=new JMatrix3D();
			tr.n11=Skin.transform.n11; tr.n12=Skin.transform.n12; tr.n13=Skin.transform.n13; tr.n14=Skin.transform.n14;
			tr.n21=Skin.transform.n21; tr.n22=Skin.transform.n22; tr.n23=Skin.transform.n23; tr.n24=Skin.transform.n24;
			tr.n31=Skin.transform.n31; tr.n32=Skin.transform.n32; tr.n33=Skin.transform.n33; tr.n34=Skin.transform.n34;
			tr.n41=Skin.transform.n41; tr.n42=Skin.transform.n42; tr.n43=Skin.transform.n43; tr.n44=Skin.transform.n44;
			 
			return tr;
		}
		
		public function setTransform(pos:JNumber3D,ori:JMatrix3D):void
		{
			Position=pos;
			Orientation=ori;
			
			var p:Number3D=new Number3D(pos.x,pos.y,pos.z);
			var o:Matrix3D=new Matrix3D();
			o.n11=ori.n11; o.n12=ori.n12; o.n13=ori.n13; o.n14=ori.n14;
			o.n21=ori.n21; o.n22=ori.n22; o.n23=ori.n23; o.n24=ori.n24;
			o.n31=ori.n31; o.n32=ori.n32; o.n33=ori.n33; o.n34=ori.n34;
			o.n41=ori.n41; o.n42=ori.n42; o.n43=ori.n43; o.n44=ori.n44;
			
			Skin.transform=Matrix3D.multiply(Matrix3D.translationMatrix(p.x, p.y, p.z), o);
		}
		
		public function GetInertiaProperties(mass:Number):JMatrix3D
		{
			return new JMatrix3D();
		}
		
		public function hitTestObject3D(obj3D:JObject3D):Boolean
		{
			var num1:Number = JNumber3D.sub(this.Position, obj3D.Position).modulo;
			var num2:Number = this.BoundingSphere + obj3D.BoundingSphere;
			
			if (num1 <= num2)
			{
				return true;
			}
			
			return false;
		}
	}
	
}
