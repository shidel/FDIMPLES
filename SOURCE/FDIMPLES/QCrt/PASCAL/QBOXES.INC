  const
    BoxData : array[bxSingle..bxDouble] of BoxStr = (
       'ڿ��ĳ', {bxSingle}
       'ַӽĺ', {bxDoubleSide}
       'ոԾͳ', {bxDoubleTop}
       'ɻȼͺ'  {bxDouble}
    );
    LineData : record
      Current : LineStr;
      Style: array[lnSingle..lnDouble,boolean,(Top, Middle, Bottom)] of LineStr;
    end = (
      Current:'�ĺ��˻�ι�ʼ�ҷ�׶�н�Ѹ�ص�Ͼ�¿�Ŵ���';
      Style:(

      ( { Single Line }
        ( { Horizontal }
          '�����������������������������������������', { Left }
          '�����������������������������������������', { Middle }
          '�Ķ��ҷ�׶�н�ҷ�׶�н�¿�Ŵ����¿�Ŵ����'  { Right }),
        ( { Vertical }
          '�³��Ѹ�ص�ص�¿�Ŵ�Ŵ�Ѹ�ص�ص�¿�Ŵ�Ŵ�', { Top }
          '�ų��ص�ص�ص�Ŵ�Ŵ�Ŵ�ص�ص�ص�Ŵ�Ŵ�Ŵ�', { Middle }
          '�����ص�ص�Ͼ�Ŵ�Ŵ����ص�ص�Ͼ�Ŵ�Ŵ��ٳ'  { Bottom })),
      ( { Double Line }
        ( { Horizontal }
          '�����������������������������������������', { Left }
          '�����������������������������������������', { Middle }
          '�͹��˻�ι�ʼ�˻�ι�ʼ�Ѹ�ص�Ͼ�Ѹ�ص�Ͼ�'  { Right }),
        ( { Vertical }
          '�Һ��˻�ι�ι�ҷ�׶�׶�˻�ι�ι�ҷ�׶�׶�', { Top }
          '�׺��ι�ι�ι�׶�׶�׶�ι�ι�ι�׶�׶�׶�', { Middle }
          '�к��ι�ι�ʼ�׶�׶�н�ι�ι�ʼ�׶�׶�н�'  { Bottom }))
      )
    );

