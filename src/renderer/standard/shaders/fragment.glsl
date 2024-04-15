#version 300 es

precision mediump float;

#define EPSILON 0.001
#define BIG 1000000.0

const int STACK_CAPACITY = 10;

const int DIFFUSE = 1;
const int DIFFUSE_REFLECTION = 1;
const int MIRROR_REFLECTION = 2;

out vec4 FragColor;
in vec3 v_position;

/////////// STRUCTURES ///////////

struct SSphere {
    vec3 Center;
    float Radius;
    int MaterialIdx;
};
struct STriangle {
    vec3 v1;
    vec3 v2;
    vec3 v3;
    int MaterialIdx;
};
struct SLight {
    vec3 Position;
};
struct SCamera {
    vec3 Position;
    vec3 View;
    vec3 Up;
    vec3 Side;
    vec2 Scale;
};
struct SRay {
    vec3 Origin;
    vec3 Direction;
};
struct SIntersection {
    float Time;
    vec3 Point;
    vec3 Normal;
    vec3 Color;

    vec4 LightCoeffs;

    float ReflectionCoef;
    float RefractionCoef;
    int MaterialType;
};
struct SMaterial {
    //diffuse color
    vec3 Color;
    // ambient, diffuse and specular coeffs
    vec4 LightCoeffs;
    // 0 - non-reflection, 1 - mirror
    float ReflectionCoef;
    float RefractionCoef;
    int MaterialType;
};
struct STracingRay {
    SRay ray;
    float contribution;
    int depth;
};

STracingRay[STACK_CAPACITY] stack;
int size = 0;

STracingRay popRay() {
    size = size - 1;
    return stack[size];
}

void pushRay(STracingRay ray) {
    stack[size] = ray;
    size = size + 1;
}

bool isEmpty() {
    return size < 1;
}

SRay GenerateRay(SCamera uCamera) {
    vec2 coords = v_position.xy * uCamera.Scale;
    vec3 direction = uCamera.View + uCamera.Side * coords.x + uCamera.Up * coords.y;
    return SRay(uCamera.Position, normalize(direction));
}

SCamera initializeDefaultCamera() {
    SCamera camera;
    camera.Position = vec3(0.0f, 0.0f, -4.99f);
    camera.View = vec3(0.0f, 0.0f, 1.0f);
    camera.Up = vec3(0.0f, 1.0f, 0.0f);
    camera.Side = vec3(1.0f, 0.0f, 0.0f);
    camera.Scale = vec2(1.0f);
    return camera;
}

void initializeDefaultScene(out STriangle triangles[12], out SSphere spheres[2]) {
    /** TRIANGLES **/

    /* left wall */
    triangles[0].v1 = vec3(-5.0f, -5.0f, -5.0f);
    triangles[0].v2 = vec3(-5.0f, 5.0f, 5.0f);
    triangles[0].v3 = vec3(-5.0f, 5.0f, -5.0f);
    triangles[0].MaterialIdx = 0;
    triangles[1].v1 = vec3(-5.0f, -5.0f, -5.0f);
    triangles[1].v2 = vec3(-5.0f, -5.0f, 5.0f);
    triangles[1].v3 = vec3(-5.0f, 5.0f, 5.0f);
    triangles[1].MaterialIdx = 0;

    /* back wall */
    triangles[2].v1 = vec3(-5.0f, -5.0f, 5.0f);
    triangles[2].v2 = vec3(5.0f, -5.0f, 5.0f);
    triangles[2].v3 = vec3(-5.0f, 5.0f, 5.0f);
    triangles[2].MaterialIdx = 1;
    triangles[3].v1 = vec3(5.0f, 5.0f, 5.0f);
    triangles[3].v2 = vec3(-5.0f, 5.0f, 5.0f);
    triangles[3].v3 = vec3(5.0f, -5.0f, 5.0f);
    triangles[3].MaterialIdx = 1;

    /* right wall */
    triangles[4].v1 = vec3(5.0f, 5.0f, 5.0f);
    triangles[4].v2 = vec3(5.0f, -5.0f, 5.0f);
    triangles[4].v3 = vec3(5.0f, 5.0f, -5.0f);
    triangles[4].MaterialIdx = 2;
    triangles[5].v1 = vec3(5.0f, 5.0f, -5.0f);
    triangles[5].v2 = vec3(5.0f, -5.0f, 5.0f);
    triangles[5].v3 = vec3(5.0f, -5.0f, -5.0f);
    triangles[5].MaterialIdx = 2;

    /* bottom wall */
    triangles[6].v1 = vec3(-5.0f, -5.0f, 5.0f);
    triangles[6].v2 = vec3(-5.0f, -5.0f, -5.0f);
    triangles[6].v3 = vec3(5.0f, -5.0f, 5.0f);
    triangles[6].MaterialIdx = 3;
    triangles[7].v1 = vec3(5.0f, -5.0f, -5.0f);
    triangles[7].v2 = vec3(5.0f, -5.0f, 5.0f);
    triangles[7].v3 = vec3(-5.0f, -5.0f, -5.0f);
    triangles[7].MaterialIdx = 3;

    /* top wall */
    triangles[8].v1 = vec3(-5.0f, 5.0f, -5.0f);
    triangles[8].v2 = vec3(-5.0f, 5.0f, 5.0f);
    triangles[8].v3 = vec3(5.0f, 5.0f, 5.0f);
    triangles[8].MaterialIdx = 4;
    triangles[9].v1 = vec3(-5.0f, 5.0f, -5.0f);
    triangles[9].v2 = vec3(5.0f, 5.0f, 5.0f);
    triangles[9].v3 = vec3(5.0f, 5.0f, -5.0f);
    triangles[9].MaterialIdx = 4;

    /* front wall*/
    triangles[10].v1 = vec3(-5.0f, -5.0f, -5.0f);
    triangles[10].v2 = vec3(5.0f, -5.0f, -5.0f);
    triangles[10].v3 = vec3(-5.0f, 5.0f, -5.0f);
    triangles[10].MaterialIdx = 5;
    triangles[11].v1 = vec3(5.0f, 5.0f, -5.0f);
    triangles[11].v2 = vec3(-5.0f, 5.0f, -5.0f);
    triangles[11].v3 = vec3(5.0f, -5.0f, -5.0f);
    triangles[11].MaterialIdx = 5;

    /** SPHERES **/
    spheres[0].Center = vec3(-1.0f, -1.0f, -1.0f);
    spheres[0].Radius = 1.0f;
    spheres[0].MaterialIdx = 6;

    spheres[1].Center = vec3(2.0f, 1.0f, 2.0f);
    spheres[1].Radius = 1.0f;
    spheres[1].MaterialIdx = 7;
}

/*Intersection */
bool IntersectSphere(SSphere sphere, SRay ray, float start, float final, out float time) {
    ray.Origin -= sphere.Center;
    float A = dot(ray.Direction, ray.Direction);
    float B = dot(ray.Direction, ray.Origin);
    float C = dot(ray.Origin, ray.Origin) - sphere.Radius * sphere.Radius;
    float D = B * B - A * C;
    if (D > 0.0f) {
        D = sqrt(D);
        //time = min(max(0, ( -B - D ) / A ), ( -B + D ) / A );
        float t1 = (-B - D) / A;
        float t2 = (-B + D) / A;
        if ((t1 < 0.0f) && (t2 < 0.0f))
            return false;

        if (min(t1, t2) < 0.0f) {
            time = max(t1, t2);
            return true;
        }
        
        time = min(t1, t2);
        return true;
    }
    return false;
}

bool IntersectTriangle(SRay ray, vec3 v1, vec3 v2, vec3 v3, out float time) {
    time = -1.0f;
    vec3 A = v2 - v1;
    vec3 B = v3 - v1;
    vec3 N = cross(A, B);
    float NdotRayDirection = dot(N, ray.Direction);
    if (abs(NdotRayDirection) < 0.001f)
        return false;
        
    float d = dot(N, v1);

    float t = -(dot(N, ray.Origin) - d) / NdotRayDirection;

    if (t < 0.0f)
        return false;

    vec3 P = ray.Origin + t * ray.Direction;

    vec3 C;

    vec3 edge1 = v2 - v1;
    vec3 VP1 = P - v1;
    C = cross(edge1, VP1);
    if (dot(N, C) < 0.0f)
        return false;

    vec3 edge2 = v3 - v2;
    vec3 VP2 = P - v2;
    C = cross(edge2, VP2);
    if (dot(N, C) < 0.0f)
        return false;

    vec3 edge3 = v1 - v3;
    vec3 VP3 = P - v3;
    C = cross(edge3, VP3);
    if (dot(N, C) < 0.0f)
        return false;

    time = t;
    return true;

}

bool Raytrace(SRay ray, SSphere spheres[2], STriangle triangles[12], SMaterial materials[8], float start, float final, inout SIntersection intersect) {
    bool result = false;
    intersect.Time = final;
    for (int i = 0; i < 2; i++) {
        SSphere sphere = spheres[i];
        bool tmp = IntersectSphere(sphere, ray, start, final, start);
        if ((tmp) && (start < intersect.Time)) {
            intersect.Time = start;
            intersect.Point = ray.Origin + ray.Direction * start;
            intersect.Normal = normalize(intersect.Point - spheres[i].Center);
            intersect.Color = materials[sphere.MaterialIdx].Color;//vec3(0.0, 1.0, 0.0);
            intersect.LightCoeffs = materials[sphere.MaterialIdx].LightCoeffs;//vec4(0.75, 0.75, 0.75, 2);
            intersect.ReflectionCoef = materials[sphere.MaterialIdx].ReflectionCoef;//1.05;
            intersect.RefractionCoef = materials[sphere.MaterialIdx].RefractionCoef;//1;
            intersect.MaterialType = materials[sphere.MaterialIdx].MaterialType;//MIRROR_REFLECTION;
            result = true;
        }
    }
    for (int i = 0; i < 12; i++) {
        STriangle triangle = triangles[i];
        if ((IntersectTriangle(ray, triangle.v1, triangle.v2, triangle.v3, start)) && (start < intersect.Time)) {
            intersect.Time = start;
            intersect.Point = ray.Origin + ray.Direction * start;
            intersect.Normal = normalize(cross(triangle.v1 - triangle.v2, triangle.v3 - triangle.v2));
            intersect.Color = materials[triangle.MaterialIdx].Color;
            intersect.LightCoeffs = materials[triangle.MaterialIdx].LightCoeffs;//vec4(0.9, 0.9, 0.9 , 512.0);
            intersect.ReflectionCoef = materials[triangle.MaterialIdx].ReflectionCoef;//1.5;
            intersect.RefractionCoef = materials[triangle.MaterialIdx].RefractionCoef;//1.0;
            intersect.MaterialType = materials[triangle.MaterialIdx].MaterialType;//DIFFUSE_REFLECTION;
            result = true;
        }
    }

    return result;
}

SLight uLight;
SMaterial materials[8];

void initializeDefaultLightMaterials(out SLight light, out SMaterial materials[8]) {
    //** LIGHT **//
    light.Position = vec3(0.0f, 4.99f, 0.0f);

    /** MATERIALS **/
    vec4 lightCoefs = vec4(0.4f, 0.9f, 0.0f, 512.0f);
    
    materials[0].Color = vec3(1.0f, 0.0f, 0.0f);
    materials[0].LightCoeffs = vec4(lightCoefs);
    materials[0].ReflectionCoef = 0.5f;
    materials[0].RefractionCoef = 1.0f;
    materials[0].MaterialType = DIFFUSE;

    materials[1].Color = vec3(0.0f, 0.0f, 1.0f);
    materials[1].LightCoeffs = vec4(lightCoefs);
    materials[1].ReflectionCoef = 0.5f;
    materials[1].RefractionCoef = 1.0f;
    materials[1].MaterialType = DIFFUSE;

    materials[2].Color = vec3(0.0f, 1.0f, 0);
    materials[2].LightCoeffs = vec4(lightCoefs);
    materials[2].ReflectionCoef = 0.5f;
    materials[2].RefractionCoef = 1.0f;
    materials[2].MaterialType = DIFFUSE;

    materials[3].Color = vec3(0.0f, 1.0f, 1.0f);
    materials[3].LightCoeffs = vec4(lightCoefs);
    materials[3].ReflectionCoef = 0.5f;
    materials[3].RefractionCoef = 1.0f;
    materials[3].MaterialType = DIFFUSE_REFLECTION;

    materials[4].Color = vec3(1.0f, 1.0f, 0.0f);
    materials[4].LightCoeffs = vec4(lightCoefs);
    materials[4].ReflectionCoef = 0.5f;
    materials[4].RefractionCoef = 1.0f;
    materials[4].MaterialType = DIFFUSE_REFLECTION;

    materials[5].Color = vec3(0.0f, 1.0f, 1.0f);
    materials[5].LightCoeffs = vec4(lightCoefs);
    materials[5].ReflectionCoef = 0.5f;
    materials[5].RefractionCoef = 1.0f;
    materials[5].MaterialType = DIFFUSE_REFLECTION;

    materials[6].Color = vec3(0.0f, 1.0f, 0.0f);
    materials[6].LightCoeffs = vec4(lightCoefs);
    materials[6].ReflectionCoef = 0.5f;
    materials[6].RefractionCoef = 1.0f;
    materials[6].MaterialType = MIRROR_REFLECTION;

    materials[7].Color = vec3(1.0f, 0.0f, 0.0f);
    materials[7].LightCoeffs = vec4(lightCoefs);
    materials[7].ReflectionCoef = 0.5f;
    materials[7].RefractionCoef = 1.0f;
    materials[7].MaterialType = MIRROR_REFLECTION;
}

vec3 Phong(SCamera uCamera, SIntersection intersect, SLight currLight, float shadowing) {
    vec3 light = normalize(currLight.Position - intersect.Point);
    float diffuse = max(dot(light, intersect.Normal), 0.0f);
    vec3 view = normalize(uCamera.Position - intersect.Point);
    vec3 reflected = reflect(-view, intersect.Normal);
    float specular = pow(max(dot(reflected, light), 0.0f), intersect.LightCoeffs.w);
    return intersect.LightCoeffs.x * intersect.Color
        + intersect.LightCoeffs.y * diffuse * intersect.Color * shadowing
        + intersect.LightCoeffs.z * specular;
}

float Shadow(SLight currLight, SIntersection intersect, SSphere spheres[2], STriangle triangles[12], SMaterial materials[8]) {
    float shadowing = 1.0f;
    vec3 direction = normalize(currLight.Position - intersect.Point);
    float distanceLight = distance(currLight.Position, intersect.Point);
    SRay shadowRay = SRay(intersect.Point + direction * EPSILON, direction);
    SIntersection shadowIntersect;
    shadowIntersect.Time = BIG;
    if (Raytrace(shadowRay, spheres, triangles, materials, 0.0f, distanceLight, shadowIntersect)) {
        shadowing = 0.0f;
    }
    return shadowing;
}

SSphere spheres[2];
STriangle triangles[12];

void main(void) {
    float start = 0.0f;
    float final = BIG;

    SCamera uCamera = initializeDefaultCamera();
    initializeDefaultLightMaterials(uLight, materials);
    SRay ray = GenerateRay(uCamera);
    SIntersection intersect;
    intersect.Time = BIG;
    vec3 resultColor = vec3(0.0f, 0.0f, 0.0f);
    initializeDefaultScene(triangles, spheres);

    STracingRay trRay = STracingRay(ray, 1.0f, 0);
    pushRay(trRay);
    while (!isEmpty()) {
        STracingRay trRay = popRay();
        ray = trRay.ray;
        SIntersection intersect;
        intersect.Time = BIG;
        start = 0.0f;
        final = BIG;
        if (!Raytrace(ray, spheres, triangles, materials, start, final, intersect)) {
            continue;
        }
        switch (intersect.MaterialType) {
            case DIFFUSE_REFLECTION: {
                float shadowing = Shadow(uLight, intersect, spheres, triangles, materials);
                resultColor += trRay.contribution * Phong(uCamera, intersect, uLight, shadowing);
                break;
            }
            case MIRROR_REFLECTION: {
                if (intersect.ReflectionCoef < 1.0f) {
                    float contribution = trRay.contribution * (1.0f - intersect.ReflectionCoef);
                    float shadowing = Shadow(uLight, intersect, spheres, triangles, materials);
                    resultColor += contribution * Phong(uCamera, intersect, uLight, shadowing);
                }
                vec3 reflectDirection = reflect(ray.Direction, intersect.Normal);
                // creare reflection ray
                float contribution = trRay.contribution * intersect.ReflectionCoef;
                STracingRay reflectRay = STracingRay(SRay(intersect.Point + reflectDirection * EPSILON, reflectDirection), contribution, trRay.depth + 1);
                pushRay(reflectRay);
                break;
            }
        }
    }

    FragColor = vec4(resultColor, 1.0f);
}
