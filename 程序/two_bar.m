%% two bar robot

% �û������Զ���q dq ddq qf���ֱ��������λ�á��ٶȡ����ٶȡ���
% �������
% actuation_force : ������������ݶ���ѧ�������
% actuation_force2 : �������������ͨ�õĶ���ѧ���������㷴��
% input_accleration : ������ٶȣ����ݶ���ѧ�������ĵ�����ٶ� 

% ���Ŷ������£�
% cm : constraint matrix������ĳ���ؽڵ�Լ������
% pm : pose matrix��λ�˾���
% vs : velocity screw(twist)���ٶ�������
% j1 : joint 1���ؽ�1��
% m1 : motion 1������1��

% ת���ؽڵ�Լ������
cm=[
1,0,0,0,0
0,1,0,0,0
0,0,1,0,0
0,0,0,1,0
0,0,0,0,1
0,0,0,0,0];

% �ؽڵ�λ����Ƕȣ�z���ǹؽڵ�ת����
j1_rpy = [0.0 0.0 0.0];
j1_xyz = [0.0 0.0 0.0];

j2_rpy = [0.0 0.0 0.0];
j2_xyz = [1.0 0.0 0.0];

pm_j1o = [eul2rotm(j1_rpy,'ZYX'), j1_xyz'
    0,0,0,1];
j1_vso = Tv(pm_j1o)*[0;0;0;0;0;1];
j1_cmo = Tf(pm_j1o)*cm;
m1_cmo = Tf(pm_j1o)*[0;0;0;0;0;1];

pm_j2o = [eul2rotm(j2_rpy,'ZYX'), j2_xyz'
    0,0,0,1];
j2_vso = Tv(pm_j2o)*[0;0;0;0;0;1];
j2_cmo = Tf(pm_j2o)*cm;
m2_cmo = Tf(pm_j2o)*[0;0;0;0;0;1];

% �����ʼλ�ø����˼��Ĺ���
I0o = eye(6);
I1o = eye(6);
I2o = eye(6);

% end effector��ĩ�ˣ�
ee_rpy = [0.0 0.0 0.0];
ee_xyz = [1.0 1.0 0.0];

pm_eeo = [eul2rotm(ee_rpy,'ZYX'), ee_xyz'
    0,0,0,1];
%% input

% �жϵ�ǰ�������Ƿ����q�ȱ�����������ڣ���ô����ʹ�ù�������q�������ʹ��Ĭ������
if ~exist('q','var')
    q = [0.6,-0.3]';
end
if(~exist('dq','var'))
    dq = [0.5, 0.3]';
end
if(~exist('ddq','var'))
    ddq =  [-0.1, 0.2]';
end
if(~exist('qf','var'))
    % ������
    qf = -[-0.115252880597922,0.369413700577896]';
end
%% problem 1�� λ������
P0 = eye(4);
P1 = P(j1_vso*q(1));
P2 = P1*P(j2_vso*q(2));

ee = P2*pm_eeo;
%% problem 2�� �ٶ��ſɱ�
J = [Tv(P0)*j1_vso, Tv(P1)*j2_vso];
%% problem 3�� �������и˼����ٶ�
% step 1
j1_cm = j1_cmo;
j2_cm = Tf(P1) * j2_cmo;

m1_cm = m1_cmo;
m2_cm = Tf(P1) * m2_cmo;

C=[
eye(6,6),       -j1_cm, zeros(6,5),     -m1_cm, zeros(6,1),
zeros(6,6),      j1_cm,     -j2_cm,      m1_cm,     -m2_cm,
zeros(6,6), zeros(6,5),      j2_cm, zeros(6,1),      m2_cm,];

% step 2
cv = [zeros(16,1);dq];

% step 3
v = C'\cv;

v0 = v(1:6);
v1 = v(7:12);
v2 = v(13:18);
%% problem 4�� ����C�������ſɱ�
CT_inv = inv(C');
J2 = CT_inv(end-5:end,end-1:end);
%% problem 5�� ���ٶ����������ϵ
dJ = [Cv(v0)*Tv(P0)*j1_vso, Cv(v1)*Tv(P1)*j2_vso];
aee = J*ddq + dJ*dq;
%% problem 6�� �����и˼��ļ��ٶ�
% step 1
dC=[
zeros(6,6),-Cf(v0)*j1_cm, zeros(6,5),    -Cf(v0)*m1_cm, zeros(6,1)
zeros(6,6), Cf(v0)*j1_cm,-Cf(v1)*j2_cm, Cf(v0)*m1_cm,-Cf(v1)*m2_cm
zeros(6,6), zeros(6,5),    Cf(v1)*j2_cm,zeros(6,1),    Cf(v1)*m2_cm];

ca = [zeros(16,1);ddq] - dC'*v;
% step 2
a = C'\ca;

a0 = a(1:6);
a1 = a(7:12);
a2 = a(13:18);
%% problem 7�� ����ѧ���
% step 1
I0=Tf(P0) * I0o * Tf(P0)';
I1=Tf(P1) * I1o * Tf(P1)';
I2=Tf(P2) * I2o * Tf(P2)';

I=blkdiag(I0,I1,I2);

% step 2
g=[0,0,-9.8,0,0,0]';

f0=-I0*g + Cf(v0)*I0*v0;
f1=-I1*g + Cf(v1)*I1*v1;
f2=-I2*g + Cf(v2)*I2*v2;

fp=[f0;f1;f2];

% step 3
ca = [zeros(16,1);ddq] - dC'*v;

% step 4
A = [-I, C;C', zeros(18,18)];
b = [fp;ca];
x = A\b;

% x ���������еĸ˼����ٶȺ����е�Լ�����������г�����������
actuation_force = x(end-1:end);
%% problem 8�� ����ѧ����
% step 0 regenerate C
C2=[
eye(6,6),       -j1_cm, zeros(6,5),
zeros(6,6),      j1_cm,     -j2_cm,
zeros(6,6), zeros(6,5),      j2_cm,];

dC2=[
zeros(6,6),-Cf(v0)*j1_cm, zeros(6,5),  
zeros(6,6), Cf(v0)*j1_cm,-Cf(v1)*j2_cm,
zeros(6,6), zeros(6,5),    Cf(v1)*j2_cm,];

% step 1
I0=Tf(P0) * I0o * Tf(P0)';
I1=Tf(P1) * I1o * Tf(P1)';
I2=Tf(P2) * I2o * Tf(P2)';

I=blkdiag(I0,I1,I2);

% step 2
g=[0,0,-9.8,0,0,0]';

f0=-I0*g + Cf(v0)*I0*v0-m1_cm*qf(1);
f1=-I1*g + Cf(v1)*I1*v1+m1_cm*qf(1)-m2_cm*qf(2);
f2=-I2*g + Cf(v2)*I2*v2+m2_cm*qf(2);

fp2=[f0;f1;f2];

% step 3
dcv2 = zeros(16,1);
ca2 = -dC2'*v+dcv2;

% step 4
A = [-I, C2; C2' zeros(16,16)];
b = [fp2;ca2];

x=A\b;

aj1 = x(7:12)-x(1:6) - Cv(v0)*v1;
aj2 = x(13:18)-x(7:12) - Cv(v1)*v2;

input_accleration = [norm(aj1(4:6));norm(aj2(4:6));];
%% problem 9�� д�ɶ���ѧͨ����ʽ
A = [-I, C
 C', zeros(18,18)    ];

B = inv(A);

M = B(end-1:end,end-1:end);
h = B(end-1:end,:)*[fp;- dC'*v];

actuation_force2 = M*ddq+h;