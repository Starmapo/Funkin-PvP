#pragma header
uniform float influence;
vec3 grayscale( vec4 color ) {
  float avg = 0.3 * color.r + 0.59 * color.g + 0.11 * color.b;
	return vec3(mix(color.r,avg,influence),mix(color.g,avg,influence),mix(color.b,avg,influence));
}

void main()
{
  vec4 color = flixel_texture2D(bitmap,openfl_TextureCoordv);
	gl_FragColor = vec4(grayscale(color),color.a);
}