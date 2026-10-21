shader_type canvas_item;
uniform float font_scale = 1.0;
uniform bool settings_page = false;
uniform bool darken = false;
vec2 resize_text(vec2 p, vec4 box) {
 vec2 center = box.xy + box.zw * 0.5;
 if (all(lessThan(abs(p-center), box.zw*0.62))) return center + (p-center)/font_scale;
 return p;
}
void fragment() {
 vec2 p = UV * vec2(2360.0,1640.0);
 if (settings_page) {
  p = resize_text(p,vec4(360.0,110.0,1630.0,330.0));
  p = resize_text(p,vec4(140.0,580.0,1000.0,240.0));
  p = resize_text(p,vec4(550.0,930.0,1180.0,230.0));
  p = resize_text(p,vec4(80.0,1300.0,1110.0,220.0));
 } else {
  p = resize_text(p,vec4(355.0,865.0,605.0,205.0));
  p = resize_text(p,vec4(285.0,1290.0,755.0,210.0));
  p = resize_text(p,vec4(1860.0,1320.0,365.0,160.0));
 }
 vec4 c = texture(TEXTURE,p/vec2(2360.0,1640.0));
 if (darken) {
  float paper=smoothstep(0.72,0.95,min(c.r,min(c.g,c.b)));
  c.rgb *= mix(0.3,1.0,paper);
 }
 COLOR = c;
}
