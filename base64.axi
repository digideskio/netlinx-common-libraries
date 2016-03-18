program_name='base64'
#if_not_defined __NCL_LIB_BASE64
#define __NCL_LIB_BASE64


define_constant
char BASE64_ENCODE_LUT[64] = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'


/**
 * Decodes a quad (4 characters) of base64-encoded material.
 *
 * @param	quad	4-byte aligned base64-encoded material
 * @return			the 3 bytes decoded from the quad
 */
define_function char[3] base64_decode_quad(char quad[4])
{
	stack_var char i
	stack_var char work[4]
	stack_var char ret[3]

	work = quad

	// decode
	for (i = 1; i <= 4; i++) {
		if (work[i] >= 'A' && work[i] <= 'Z') {
			work[i] = work[i] - 'A'
		}
		else if (work[i] >= 'a' && work[i] <= 'z') {
			work[i] = work[i] - 'a' + 26
		}
		else if (work[i] >= '0' && work[i] <= '9') {
			work[i] = work[i] - '0' + 52
		} else if (work[i] == '+') {
			work[i] = 62
		} else {
			work[i] = 63
		}
	}

	// bitshift
	ret[1] = type_cast((work[1] << 2) | (work[2] >> 4))
	ret[2] = type_cast(((work[2] & $0f) << 4) | work[3] >> 2)
	ret[3] = type_cast(((work[3] & $03) << 6) | work[4])

	// final character finding
	if (quad[3] == '=') {
		set_length_string(ret, 1)
	} else if (quad[4] == '=') {
		set_length_string(ret, 2)
	} else {
		set_length_string(ret, 3)
	}

	return ret
}

/**
 * Encodes string with standard base64 encoding. Does NOT support binary data.
 *
 * @param	to_encode		string to encode
 * @param	encoded 		encoded string
 * @param 	line_length 	amount of encoded characters before a line feed
 *							is added. this is useful for formatted output.
 *							set to 0 to not use this feature. a good value
 *							for large blocks is 76.
 * @todo 					write a much faster, binary-safe version
 *							(reserving 'base64_decode' function for this)
 */
define_function base64_encode_str(char to_encode[], char encoded[], line_length)
{
	stack_var long i
	
	stack_var char work[3]
	stack_var char enc[5]
	
	stack_var integer slen
	stack_var long    lnext
		

	slen = length_string(to_encode)
	encoded = ''
	
	if (slen == 0) {
		return
	}
	
	lnext = 0

	for (i = 1; i <= slen; i = i + 3) {
		work[1] = to_encode[i]
		switch (slen - i) {
			case 0:
				work[2] = $00
				work[3] = $00
			case 1:
				work[2] = to_encode[i + 1]
				work[3] = $00
			default:
				work[2] = to_encode[i + 1]
				work[3] = to_encode[i + 2]
		}

		enc = "BASE64_ENCODE_LUT[(work[1] >> 2) + 1],
				BASE64_ENCODE_LUT[(((work[1] & $03) << 4) | (work[2] >> 4)) + 1],
				BASE64_ENCODE_LUT[(((work[2] & $0f) << 2) | (work[3] >> 6)) + 1],
				BASE64_ENCODE_LUT[(work[3] & $3f) + 1]"

		if (slen - i == 1) {
			enc[4] = '='
		} else if (slen - i == 0) {
			enc[3] = '='
			enc[4] = '='
		}
		
		encoded = "encoded, enc"

		if (line_length) {
			if ((i % line_length) < lnext) {
				lnext = 0
				encoded = "encoded, $0d, $0a"
			} else {
				lnext = i % line_length;
			}
		}
	}
	
	if (line_length && right_string(encoded, 2) == "$0d, $0a") {
		encoded = left_string(encoded, length_string(encoded) - 2)
	}
}

/**
 * Decodes string with standard base64 encoding. Does NOT support binary data.
 *
 * @param	to_decode	base64-encoded string to decode
 * @param	decoded 	decoded string
 * @todo 				write a much faster, binary-safe version
 *						(reserving 'base64_decode' function for this)
 *
 */
define_function integer base64_decode_str(char to_decode[65532], char decoded[49419])
{
	stack_var long i
	stack_var integer j
	stack_var char work[4]
	stack_var char dec[3]

	decoded = ''

	for (i = 1; i <= length_string(to_decode); i++) {
		for (j = 1; j <= 64; j++) {
			if (to_decode[i] == BASE64_ENCODE_LUT[j]) {
				work = "work, to_decode[i]"
				if (length_array(work) == 4) {
					decoded = "decoded, base64_decode_quad(work)"
					work = ''
				}
				continue
			}
		}
		if (to_decode[i] == '=') {
			work = "work, to_decode[i]"
			if (length_array(work) == 4) {
				decoded = "decoded, base64_decode_quad(work)"
				work = ''
			}
		}
	}

	if (length_string(work)) {
		decoded = "decoded, base64_decode_quad(work)"
	}
}