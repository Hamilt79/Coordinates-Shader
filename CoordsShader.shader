Shader "Hamilt79/CoordsShader"
{
    Properties
    {
        // Color
        _Color("Color", Color) = (0,0,0,0)
        // Numbers texture
        _MainTex("Nums", 2D) = "White" {}

        //--------------------------Coord specify section--------------------------//
        // Only one can be on at a time. Use multiple materials if you want all three
        // They are named _COLORCOLOR, _FADING, and _COLOROVERLAY so they don't take up
        // additional shader keywords in-game

        // Show X Coord Bool
        [Toggle]_COLORCOLOR("X", Float) = 0
        // Show Y Coord Bool
        [Toggle]_FADING("Y", Float) = 0
        // Show Z Coord Bool
        [Toggle]_COLOROVERLAY("Z", Float) = 0
    }
    SubShader
    {
        Tags { "Queue"="Transparent" }
        ZWrite Off

        // Allow transparency
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            // Property declarations
            sampler2D _MainTex;
            float4 _MainTex_ST;

            // Default vert function
            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            float2 Transform_Tex_2(float2 texCoord, float4 tex) {
                return (texCoord.xy * tex.xy + tex.zw);
            }

            // Get number of digits needed using some MATH!
            int getNumOfDigits(int num) {
                if (num == 0) {
                    return 1;
                }

                int numOfDigits = 0;
                while (num != 0) {
                    numOfDigits++;
                    num /= 10;
                }
                return numOfDigits;
            }

            // Get position of number relative to number texture
            int getNumInPos(int num, int pos) {

                int numOfDigits = getNumOfDigits(num);

                int finalNum = num;

                if (pos != numOfDigits - 1) {
                    int div = 10;
                    for (int i = 0; i < numOfDigits - pos - 2; ++i) {
                        div *= 10;
                    }
                    finalNum /= div;
                }

                finalNum %= 10;

                if (finalNum < 0) {
                    finalNum *= -1;
                }

                return finalNum;
            }

            // Get the "." offset needed
            float GetDotOffsetFromNum(int currentPos) {
                // 11 is the "." index in the number atlas
                int numToGet = 11;
                // Out of twelve cause thats how many sections the number atlas is in
                float offset = 1.0 / 12.0;
                float index = (((numToGet - 9) * -1) + 2);
                return (offset * (index - currentPos));
            }

            // Get the number offset needed
            float GetNumOffsetFromNum(int numToGet, int currentPos) {
                // Out of twelve cause thats how many sections the number atlas is in
                float offset = 1.0 / 12.0;
                float index = (((numToGet - 9) * -1) + 2);
                return (offset * (index - currentPos));
            }

            // Fragment property declarations
            float4 _Color;
            float _COLORCOLOR;
            float _FADING;
            float _COLOROVERLAY;

            fixed4 frag(v2f i) : SV_Target
            {
                fixed4 col = 0;
                // Getting gameobjects world position
                float4 worldPos = mul(unity_ObjectToWorld, float4(0, 0, 0, 1));
                int numToDisplay = 0;
                // Checking for boolean on/off values for x y or z respectively
                if(_COLORCOLOR){
                    numToDisplay = worldPos.x * 100;
                }
                if (_FADING) {
                    numToDisplay = worldPos.y * 100;
                }
                if (_COLOROVERLAY) {
                    numToDisplay = worldPos.z * 100;
                }
                float offset = 1.0 / 12.0;
                int numOfDigits = getNumOfDigits(numToDisplay);
                int numIndex = 0;
                if (numToDisplay < 0 && i.uv.x < offset) {
                    float2 temp = i.uv;
                    temp += offset;
                    col += tex2D(_MainTex, temp);
                }
                numIndex++;
                int aheadOne = 0;
                // I made this years ago and didn't document ANYTHING
                // The fact I have no idea how this works now is a huge
                // wakeup call....
                // There is 100% a simpler way to do this, but this was the extent of my knowledge in 2020
                for (int j = 0; j < numOfDigits + 1; ++j) {
                    if (numOfDigits < 2) {
                        if (j >= numOfDigits - 2) {
                            aheadOne = 1;
                        }
                        if (j == numOfDigits - 1 && i.uv.x < offset * (numIndex + 1) && i.uv.x > offset * (numIndex)) {
                            float2 temp = i.uv;
                            temp.x += GetDotOffsetFromNum(numIndex);
                            col += tex2D(_MainTex, temp);
                            aheadOne = 2;
                        }
                        int localNum = getNumInPos(numToDisplay, numIndex - 1 - aheadOne);
                        if (aheadOne != 2) {
                            if (i.uv.x < offset * (numIndex + 2) && i.uv.x > offset * (numIndex + 1)) {
                                float2 temp = i.uv;
                                temp.x += GetNumOffsetFromNum(localNum, numIndex + 1);
                                col += tex2D(_MainTex, temp);
                            }
                        }
                        numIndex++;
                    }
                    else {
                        if (j >= numOfDigits - 2) {
                            aheadOne = 1;
                        }
                        if (j == numOfDigits - 2 && i.uv.x < offset * (numIndex + 1) && i.uv.x > offset * (numIndex)) {
                            float2 temp = i.uv;
                            temp.x += GetDotOffsetFromNum(numIndex);
                            col += tex2D(_MainTex, temp);
                            aheadOne = 2;
                        }
                        int localNum = getNumInPos(numToDisplay, numIndex - 1 - aheadOne);
                        if (aheadOne != 2) {
                            if (i.uv.x < offset * (numIndex + 1) && i.uv.x > offset * (numIndex)) {
                                float2 temp = i.uv;
                                temp.x += GetNumOffsetFromNum(localNum, numIndex);
                                col += tex2D(_MainTex, temp);
                            }
                        }
                        numIndex++;
                    }
                }
                col.rgb = _Color.rgb;
                return col;
            }
            ENDCG
        }
    }
}
