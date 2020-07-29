IF OBJECT_ID('tempdb..#TB_WKTID') IS NOT NULL
DROP TABLE #TB_WKTID
IF OBJECT_ID('tempdb..#TB_FZ') IS NOT NULL
DROP TABLE #TB_FZ
IF OBJECT_ID('tempdb..#TB_SH') IS NOT NULL
DROP TABLE #TB_SH
IF OBJECT_ID('tempdb..#TB_SG') IS NOT NULL
DROP TABLE #TB_SG

DECLARE @MO_KEYID INT
SET @MO_KEYID = 6141
SELECT 
	C.WktID
	INTO #TB_WKTID
FROM
	PR_SendBill A
	LEFT JOIN dbo.PR_SendWkt AS B ON B.KeyID = A.KeyID AND B.WPID IN (select WPID from BA_v_StandardWPItem where SectionID=36 and IsStat=1)
	RIGHT JOIN PR_WktData C ON C.WktID = B.WktID 
WHERE
	A.MO_KeyID = @MO_KEYID 
	AND A.SectionID = 36
----------------------------------------发织表
SELECT
	B.BillNo,
	A.DeptID,
	C.MO,
	C.StyleID,
	CONVERT(VARCHAR(10),B.BillDate,23) AS	BillDate,
 	CONVERT(VARCHAR(10),B.ExpireDate,23)AS	ExpireDate,
	A.ColorName,
	D.SizeName,
	D.OrderID,
	A.Qty,
	0 AS SQTY
INTO #TB_FZ -- 发织表
FROM
	dbo.PR_SendDetail A
	LEFT JOIN dbo.PR_SendBill B ON B.KeyID = A.KeyID 
	LEFT JOIN dbo.PR_MO C ON C.KeyID = A.MO_KeyID 
	LEFT JOIN dbo.SC_v_PropertySizeEntity AS D ON D.KeyID = C.PR_KeyID AND A.sizeName = D.SizeName
WHERE
	A.MO_KeyID =@MO_KEYID AND
	A.WPID IN (select WPID from BA_v_StandardWPItem where SectionID=36 and IsStat=1)
ORDER BY
	A.ColorName,
	D.OrderID
	
	
	-----------------------------------------------------条码收货表
SELECT
	D.BillNo,
	B.ColorName,
	B.SizeName,
	SUM ( A.Qty ) AS SQTY 
	INTO #TB_SH -- 条码收货表
FROM
	PR_AcceptWkt A
	LEFT JOIN PR_AcceptDetail B ON B.DetailID = A.DetailID 
	LEFT JOIN PR_WktData C ON C.WktID = A.WktID 
	LEFT JOIN PR_SendBill D ON D.KeyID = C.BillKeyID
WHERE
	A.WktID IN (SELECT * FROM #TB_WKTID)  
	AND A.WPID IN (select WPID from BA_v_StandardWPItem where SectionID=36 and IsStat=1)
GROUP BY
	D.BillNo,
	B.ColorName,
	B.SizeName
	
UPDATE A SET A.SQTY = ISNULL(B.SQTY, 0) FROM #TB_FZ A LEFT JOIN #TB_SH B ON 
A.ColorName = B.ColorName AND A.SizeName = B.SizeName AND A.Qty > 0 AND A.BillNo = B.BillNo

--------------------------------------------------手工收货表
SELECT
ColorName,
SizeName,
SUM ( Qty ) AS SGQty 
INTO #TB_SG -- 手工收货表
FROM
	dbo.PR_v_AcceptDetail AS A 
WHERE
	A.MO_KeyID = @MO_KEYID 
	AND A.WPID IN (select WPID from BA_v_StandardWPItem where SectionID=36 and IsStat=1)
	AND A.DetailID NOT IN (
		SELECT DISTINCT
		DetailID
	FROM
		PR_AcceptWkt 
	WHERE
		WktID IN ( SELECT * FROM #TB_WKTID ) 
		AND WPID IN (select WPID from BA_v_StandardWPItem where SectionID=36 and IsStat=1)
	) 
GROUP BY
	MO,
	StyleID,
	ColorName,
	SizeName
	
UPDATE  A SET  A.SQTY = A.SQTY + ISNULL(B.SGQty, 0) FROM #TB_FZ A LEFT JOIN #TB_SG B ON A.ColorName = B.ColorName AND A.SizeName = B.SizeName AND A.Qty > 0

-- SELECT * FROM #TB_FZ
SELECT SUM(Qty) - SUM(CASE 
	WHEN SQTY > Qty AND Qty > 0 THEN Qty
	ELSE SQTY
END)  AS Qty FROM #TB_FZ