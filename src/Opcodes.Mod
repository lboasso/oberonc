(*
  Copyright 2017 Luca Boasso.
  Use of this source code is governed by a MIT
  license that can be found in the LICENSE file.
*)

MODULE Opcodes;
  CONST
    (* access flags *)
    ACCxPUBLIC* = 0001H;
    ACCxPRIVATE* = 0002H;
    ACCxSTATIC* = 0008H;
    ACCxFINAL* = 0010H;
    ACCxSUPER* = 0020H;
    ACCxABSTRACT* = 0400H;

    (* types for NEWARRAY *)
    TBOOLEAN* = 4;
    TCHAR* = 5;
    TFLOAT* = 6;
    TBYTE* = 8;
    TINT* = 10;

    (* opcodes *)
    ACONSTNULL* = 1;
    ICONSTM1* = 2;
    ICONST0* = 3;
    ICONST1* = 4;
    ICONST2* = 5;
    ICONST3* = 6;
    ICONST4* = 7;
    ICONST5* = 8;
    FCONST0* = 11;
    FCONST1* = 12;
    FCONST2* = 13;
    BIPUSH* = 16;
    SIPUSH* = 17;
    LDC* = 18;
    LDCW* = 19;
    ILOAD* = 21;
    FLOAD* = 23;
    ALOAD* = 25;
    IALOAD* = 46;
    FALOAD* = 48;
    AALOAD* = 50;
    BALOAD* = 51;
    CALOAD* = 52;
    ISTORE* = 54;
    FSTORE* = 56;
    ASTORE* = 58;
    IASTORE* = 79;
    FASTORE* = 81;
    AASTORE* = 83;
    BASTORE* = 84;
    CASTORE* = 85;
    POP* = 87;
    POP2* = 88;
    DUP* = 89;
    DUP2* = 92;
    SWAP* = 95;
    IADD* = 96;
    FADD* = 98;
    ISUB* = 100;
    FSUB* = 102;
    IMUL* = 104;
    FMUL* = 106;
    FDIV* = 110;
    INEG* = 116;
    FNEG* = 118;
    ISHL* = 120;
    ISHR* = 122;
    IAND* = 126;
    IOR* = 128;
    IXOR* = 130;
    IINC* = 132;
    I2F* = 134;
    F2D* = 141;
    D2I* = 142;
    FCMPL* = 149;
    FCMPG* = 150;
    IFEQ* = 153;
    IFNE* = 154;
    IFLT* = 155;
    IFGE* = 156;
    IFGT* = 157;
    IFLE* = 158;
    IFICMPEQ* = 159;
    IFICMPNE* = 160;
    IFICMPLT* = 161;
    IFICMPGE* = 162;
    IFICMPGT* = 163;
    IFICMPLE* = 164;
    IFACMPEQ* = 165;
    IFACMPNE* = 166;
    GOTO* = 167;
    TABLESWITCH* = 170;
    IRETURN* = 172;
    FRETURN* = 174;
    ARETURN* = 176;
    RETURNx* = 177;
    GETSTATIC* = 178;
    PUTSTATIC* = 179;
    GETFIELD* = 180;
    PUTFIELD* = 181;
    INVOKEVIRTUAL* = 182;
    INVOKESPECIAL* = 183;
    INVOKESTATIC* = 184;
    INVOKEINTERFACE* = 185;
    NEW* = 187;
    NEWARRAY* = 188;
    ANEWARRAY* = 189;
    ARRAYLENGTH* = 190;
    ATHROW* = 191;
    CHECKCAST* = 192;
    INSTANCEOF* = 193;
    MULTIANEWARRAY* = 197;
    IFNULL* = 198;
    IFNONNULL* = 199;
    GOTOW* = 200;
END Opcodes.
