ALTER PROCEDURE [dbo].[getRemaining](
	@MO_KEYID INT,
	@REMAIN INT out
)
AS
BEGIN

/* 当前还存在一些问题
*  1. 当存在补货情况时,假设补货的数量颜色尺寸跟之前的一致时 在手工单UPDATE 阶段可能会 造成数量翻倍
*  时间:2020-7-22 16:50
*  修改 尺码排列顺序
*  时间 2020-07-24 15:41
*/
-- SET NOCOUNT ON 
-- DECLARE @MO_KEYID INT, @KEYID INT
-- SET @MO_KEYID = 6141


-- SELECT
-- 	@KEYID = KeyID 
-- FROM
-- 	PR_SendBill 
-- WHERE
-- 	MO_KeyID = @MO_KEYID 
-- 	AND SectionID = 36
---------------------条码表  存放发织的所有条码 结果可能带null
SELECT 
	C.WktID
	INTO #TB_WKTID
FROM
	PR_SendBill A
	LEFT JOIN dbo.PR_SendWkt AS B ON B.KeyID = A.KeyID AND B.WPID LIKE '%07%'
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
	A.WPID LIKE '07%'
ORDER BY
	A.ColorName,
	D.OrderID
--	SELECT * FROM #TB_FZ
	
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
	AND A.WPID LIKE '07%' 
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
	AND A.WPID LIKE '07%' 
	AND A.DetailID NOT IN (
		SELECT DISTINCT
		DetailID
	FROM
		PR_AcceptWkt 
	WHERE
		WktID IN ( SELECT * FROM #TB_WKTID ) 
		AND WPID LIKE '07%' 
	) 
GROUP BY
	MO,
	StyleID,
	ColorName,
	SizeName
	
UPDATE  A SET  A.SQTY = A.SQTY + ISNULL(B.SGQty, 0) FROM #TB_FZ A LEFT JOIN #TB_SG B ON A.ColorName = B.ColorName AND A.SizeName = B.SizeName AND A.Qty > 0


SELECT SUM(Qty) - SUM(
CASE WHEN SQTY > Qty THEN Qty
	ELSE SQTY
	END
) AS remain FROM #TB_FZ

-- TRUNCATE TABLE #TB_FZ
-- DROP TABLE #TB_FZ
-- TRUNCATE TABLE #TB_SH
-- DROP TABLE #TB_SH
-- TRUNCATE TABLE #TB_SG
-- DROP TABLE #TB_SG
-- TRUNCATE TABLE #TB_WKTID
-- DROP TABLE #TB_WKTID

END