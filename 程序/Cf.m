function Cf = Cf(vs)
%UNTITLED3 �˴���ʾ�йش˺�����ժҪ
%   �˴���ʾ��ϸ˵��
    w = vs(4:6);
    v = vs(1:3);

    Cf = [
    C3(w)         zeros(3,3)
    C3(v)      C3(w) ];
end

