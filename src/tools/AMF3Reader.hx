/*
 * format - haXe File Formats
 *
 * Copyright (c) 2008, The haXe Project Contributors
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *   - Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *   - Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE HAXE PROJECT CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE HAXE PROJECT CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 */
package tools;
import tools.Value;

class AMF3Reader {

	var i : haxe.io.Input;

	public function new( i : haxe.io.Input ) {
		this.i = i;
		i.bigEndian = true;
	}

	function readObject() {
		var h = new Map();
		while( true ) {
			var c1 = i.readByte();
			var c2 = i.readByte();
			var name = i.readString((c1 << 8) | c2);
			var k = i.readByte();
			if( k == 0x09 )
				break;
			h.set(name,readWithCode(k));
		}
		return h;
	}

	function readArray(n : Int) {
		var a = new Array();
		read();
		for( i in 0...n )
			a.push(read());
		return a;
	}
	
	function readInt() {
		var ret = 0;
		var c = i.readByte();
		while (c > 0x7f) {
			ret |= c & 0x7f;
			ret <<= 7;
			c = i.readByte();
		}
		if (ret > 0xfffff) ret <<= 1;
		ret |= c;
		return ret;
	}

	public function readWithCode( id ) {
		var i = this.i;
		return switch( id ) {
		case 0x00:
			AUndefined;
		case 0x01:
			ANull;
		case 0x02:
			ABool(false);
		case 0x03:
			ABool(true);
		case 0x04:
			AInt( readInt() ); // fancy int reading bytes stuff
		case 0x05:
			ANumber( i.readDouble() );
		case 0x06:
			AString( i.readString(readInt() >> 1) ); // last bit of "length" byte is something idk, get rid of it
		case 0x09:
			AArray( readArray(readInt() >> 1) ); // something else here
		// plus some other ones
		default:
			throw "Unknown AMF "+id;
		}
	}

	public function read() {
		return readWithCode(i.readByte());
	}
}