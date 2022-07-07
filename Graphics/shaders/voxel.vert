#version 460 core

layout (location = 0) in vec3 vertex_position;
layout (location = 1) in vec3 cube_pos;
layout (location = 2) in vec3 cube_color;
layout (location = 3) in uint index;
uniform mat4 projection_mat, view_mat, model_mat;
uniform vec3 chunk_pos[50];
out vec3 position_eye, normal_eye;

//out vec3 Fragpos;
flat out vec3 objectColor;

void main () {
	position_eye = vec3(view_mat * model_mat * vec4(vertex_position + cube_pos + chunk_pos[index], 1.0));
	normal_eye = vec3(view_mat * model_mat * vec4(vertex_position + cube_pos + chunk_pos[index], 0.0));

	gl_Position = projection_mat * vec4(position_eye, 1.0);

	//Fragpos = vec3(model_mat * vec4(position_eye, 1.0));
	objectColor = cube_color;

}
