SELECT ${IF(SampleNO == ''&& Status =='','TOP 20','')}
A.Picture AS [图片],
A.SampleNo AS [版单号],
A.StyleID AS [款号],
A.TotalQty AS [数量],
CONVERT(VARCHAR(100), A.ExpireDate, 111) AS [计划完成日期],
CONVERT(VARCHAR(100), A.Makedate, 111) AS [开单日期],
A.Pins AS [针种],
A.Master AS [做办师傅],
CONVERT(VARCHAR(100), A.Item366, 111) AS [打样完成日期],
A.Yieldly AS [工艺员],
A.Quota AS [制版员],
CONVERT(VARCHAR(100), A.Item307, 111) AS [制版完成时间],
CONVERT(VARCHAR(100), A.Item457, 111) AS [配纱完成时间],
CONVERT(VARCHAR(100), A.Item461, 111) AS [横机下机时间],
CONVERT(VARCHAR(100), A.Item656, 111) AS [套口完成时间],
CONVERT(VARCHAR(100), A.Item841, 111) AS [洗水完成时间],
CONVERT(VARCHAR(100), A.Item847, 111) AS [后整完成时间],
A.Item538 AS [脱期原因],
A.Item540 AS [备注],
CONVERT(VARCHAR(100), A.Item303, 111) AS [工艺完成时间],
B.CompanyName AS [客户],
C.ProductTypeName AS [产品类别]

FROM
dbo.PL_v_SampleTodo AS A
INNER JOIN dbo.BA_v_Customer AS B ON A.CustomerID = B.CompanyID
INNER JOIN dbo.BA_ProductType AS C ON A.ProductTypeID = C.ProductTypeID

WHERE
${IF(SampleNO == '','1=1',"A.SampleNo ='"+ SampleNO +"'")}
AND
${IF(Status == 0,'A.Status = 0',IF(Status == 1,'A.Status >= 200','A.Status = 4'))}
ORDER BY A.ExpireDate DESC

