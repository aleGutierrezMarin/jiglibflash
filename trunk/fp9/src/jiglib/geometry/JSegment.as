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
	import jiglib.math.JNumber3D;				

	public class JSegment {

		private var _origin:JNumber3D;
		private var _delta:JNumber3D;

		public function JSegment(origin:JNumber3D, delta:JNumber3D) {
			_origin = origin;
			_delta = delta;
		}

		public function set origin(ori:JNumber3D):void {
			_origin = ori;
		}

		public function get origin():JNumber3D {
			return _origin;
		}

		public function set delta(del:JNumber3D):void {
			_delta = del;
		}

		public function get delta():JNumber3D {
			return _delta;
		}

		public function getPoint(t:Number):JNumber3D {
			return JNumber3D.add(_origin, JNumber3D.multiply(_delta, t));
		}

		public function getEnd():JNumber3D {
			return JNumber3D.add(_origin, _delta);
		}

		public function clone():JSegment {
			return new JSegment(_origin, _delta);
		}
	}
}
