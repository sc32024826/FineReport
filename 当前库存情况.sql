SELECT
	A.KeyID,
	A.VatNo,
	ISNULL(A.StyleID, '') AS StyleID,
	SUM ( ISNULL(A.Qty, 0) ) AS PlanTotalQty,
	CONVERT ( VARCHAR ( 10 ), A.BillDate, 23 ) AS MakeDate,
	CONVERT ( VARCHAR ( 10 ), DATEADD( DD, 30, A.BillDate ), 23 ) AS ExpireDate,
	'' AS DeptName
	INTO #TB_A
FROM
	dbo.SU_v_MaterialStockBillPO_List A
	RIGHT JOIN (SELECT DISTINCT
	B.StockID 
FROM
	dbo.SU_v_MaterialStock AS A
	LEFT JOIN SU_MaterialStock B ON B.MaterialName = A.MaterialName 
WHERE
	A.DepotID = 8) AS B ON A.StockID = B.StockID
GROUP BY
	A.KeyID,
	A.VatNo,
	A.StyleID,
	A.BillDate

SELECT 
	A.VatNo,
	CAST(SUM(A.StockQty)AS INT) AS StockQty
	INTO #TB_B
FROM
	SU_v_MaterialStock A
	INNER JOIN 
(SELECT DISTINCT
	B.StockID 
FROM
	dbo.SU_v_MaterialStock AS A
	LEFT JOIN SU_MaterialStock B ON B.MaterialName = A.MaterialName 
WHERE
	A.DepotID = 8) B ON A.StockID = B.StockID
GROUP BY
	A.VatNo
	
	SELECT A.* , B.StockQty FROM #TB_A A INNER JOIN #TB_B B ON B.VatNo = A.VatNo
	
	DROP TABLE #TB_A
	DROP TABLE #TB_B