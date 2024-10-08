#ifdef GL_ES
precision mediump float;
#endif

#extension GL_OES_standard_derivatives : enable

uniform float u_Time;
uniform sampler2D u_Tex0;
varying vec2 v_TexCoord;
uniform vec2 u_WalkOffset;

float rainLayer(vec2 uv, float scale, float ttime)
{
  float w = smoothstep(1.0, 0.0, -uv.y * (scale / 5.0)); 
  if (w < 0.1) return 0.0;

  uv += ttime * 0.5 / scale;
  uv.y += ttime * 2.5 / scale;
  uv.x += sin(uv.y + ttime * 0.10) / scale;
  uv *= 1.2 * scale;
  vec2 s = floor(uv);
  vec2 f = fract(uv);
  vec2 p;

  float k = 3.0;
  float d = 0.0;

  p = 0.5 + 0.35 * sin(11.0 * fract(sin((s + p + scale) * mat2(7.0, 3.0, 6.0, 5.0)) * 5.0)) - f;

  d = length(p);
  k = min(d, k);
  k = smoothstep(0.0, k, sin(f.x + f.y) * 0.01);
  return k * w;
}

void main(void)
{
  vec4 Game = texture2D(u_Tex0, v_TexCoord);
  vec2 uv = ((gl_FragCoord.xy) * 2.5) / 200.0 + vec2(u_WalkOffset.x, u_WalkOffset.y);

  float ttime = mod(u_Time * 1.0, 1000.0);

  uv.x -= (uv.y) * 0.9;
  uv.y += 1.0;
  uv.y = dot(uv * 0.055, uv * 0.125);

  float rain = 0.0;

  rain += rainLayer(uv, 2.0, ttime);
  rain += rainLayer(uv, 3.0, ttime);
  rain += rainLayer(uv, 4.0, ttime);

  float opacity = 0.15;

  vec4 _output = Game + vec4(rain * opacity); // Ensure _output is vec4

  gl_FragColor = _output;
}
