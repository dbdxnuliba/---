function Cv = Cv(vs)
%UNTITLED3 �˴���ʾ�йش˺�����ժҪ
%   �˴���ʾ��ϸ˵��
    w = vs(4:6);
    v = vs(1:3);

    Cv = [
    C3(w)      C3(v)
    zeros(3,3) C3(w) ];
end

