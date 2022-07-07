#version 460 core

in vec3 position_eye, normal_eye;
uniform mat4 projection_mat;
//in vec3 Fragpos;
flat in vec3 objectColor;

out vec3 fragColor;

void main()
{
    //vec3 norm = normalize(normal_eye);
    //vec3 lightDir = normalize(lightPos - Fragpos);

    //float diff = max(dot(norm, lightDir), 0.0);
    //vec3 diffuse = diff * lightColor;

    //vec3 result = (ambient + diffuse) * objectColor;
    fragColor = vec3(objectColor);

}