SET NOCOUNT ON

IF OBJECT_ID('tempdb..#TB_MO') IS NOT NULL
    DROP TABLE #TB_MO;   --释放临时表
IF OBJECT_ID('tempdb..#TB_A') IS NOT NULL
		DROP TABLE #TB_A
IF OBJECT_ID('tempdb..#TB_HJ') IS NOT NULL
		DROP TABLE #TB_HJ
IF OBJECT_ID('tempdb..#TB_TK') IS NOT NULL
		DROP TABLE #TB_TK
IF OBJECT_ID('tempdb..#TB_XS') IS NOT NULL
		DROP TABLE #TB_XS
IF OBJECT_ID('tempdb..#TB_ZT') IS NOT NULL
		DROP TABLE #TB_ZT
IF OBJECT_ID('tempdb..#TB_CJ') IS NOT NULL
		DROP TABLE #TB_CJ
IF OBJECT_ID('tempdb..#TB_BZ') IS NOT NULL
		DROP TABLE #TB_BZ
IF OBJECT_ID('tempdb..#TB_TIME') IS NOT NULL
		DROP TABLE #TB_TIME
IF OBJECT_ID('tempdb..#TB_LAST') IS NOT NULL
		DROP TABLE #TB_LAST
IF OBJECT_ID('tempdb..#TB_template') IS NOT NULL
		DROP TABLE #TB_template
IF OBJECT_ID('tempdb..#TB_RES') IS NOT NULL
		DROP TABLE #TB_RES
		
DECLARE @KEYID INT,@REMAIN INT

SELECT A.KeyID,A.MO,A.StyleID,A.TotalQty AS [计划数],CONVERT(NVARCHAR(50), A.MakeDate, 23) AS MakeDate,CONVERT(NVARCHAR(50), A.ExpireDate, 23) AS ExpireDate,
0 AS [横机在制品]
/*
0 AS [发织数],--发货数
0 AS [横机收货数],0 AS [套口收货数],0 AS [洗水收货数],0 AS [整烫收货数],0 AS [成检收货数],0 AS [包装收货数],--收货数
0 AS [横机今日收货数],0 AS [套口今日收货数],0 AS [洗水今日收货数],0 AS [整烫今日收货数],0 AS [成检今日收货数],0 AS [包装今日收货数],--今日收获数
0 AS [横机昨日收货数],0 AS [套口昨日收货数],0 AS [洗水昨日收货数],0 AS [整烫昨日收货数],0 AS [成检昨日收货数],0 AS [包装昨日收货数]--昨日收货数
*/
-- CAST(NULL AS DATETIME) AS ZzDt,CAST(NULL AS DATETIME) AS ZjDt--最早 最晚流转时间
INTO #TB_MO
FROM
	dbo.PR_v_MO A
	WHERE
	A.BillStatusType NOT IN (0,2,3) AND A.StyleID <> 'TEST01'
/*

---------------------横机数据----------------------------------------------------------------------

SELECT
	A.MO_KeyID, 
	SUM(ISNULL(A.Qty, 0)) AS Qty, -- 累计收获
	0 AS JR, -- 今日收获数
	0 AS ZR	-- 昨日收货数
	INTO #TB_A
FROM 
	dbo.PR_AcceptDetail AS A
	RIGHT JOIN #TB_MO B ON A.MO_KeyID = B.KeyID
WHERE
	A.WPID IN (select WPID from BA_v_StandardWPItem where SectionID=36 and IsStat=1)
GROUP BY
	A.MO_KeyID
	
--更新横机收发数
SELECT
	A.MO_KeyID,
	SUM(ISNULL(A.Qty, 0)) AS FQty, -- 发织数
	ISNULL(C.Qty,0) AS Qty,
	ISNULL(C.JR,0) AS JR,
	ISNULL(C.ZR,0) AS ZR
	INTO #TB_HJ
FROM
	dbo.PR_SendDetail AS A
	RIGHT JOIN #TB_MO B ON A.MO_KeyID = B.KeyID
	LEFT JOIN #TB_A C ON C.MO_KeyID = A.MO_KeyID
WHERE
	A.WPID IN (select WPID from BA_v_StandardWPItem where SectionID=36 and IsStat=1)
	GROUP BY
	A.MO_KeyID,
	C.Qty,
	C.JR,
	C.ZR

-------------------------------更新 今日横机收货数--------------------------------------------------------

UPDATE A  SET A.JR = B.JR FROM #TB_HJ A INNER JOIN

(SELECT MO_KeyID,SUM(ISNULL(Qty,0)) AS JR FROM PR_AcceptDetail A RIGHT JOIN #TB_MO B ON B.KeyID = A.MO_KeyID

WHERE A.WPID IN (select WPID from BA_v_StandardWPItem where SectionID=36 and IsStat=1) AND  DATEDIFF(DD,A.BillDate , GETDATE()) = 0
GROUP BY A.MO_KeyID) B ON B.MO_KeyID = A.MO_KeyID


-------------------------------更新 昨日横机收货数--------------------------------------------------------

UPDATE A  SET A.ZR = B.ZR FROM #TB_HJ A INNER JOIN

(SELECT MO_KeyID,SUM(ISNULL(Qty,0)) AS ZR FROM PR_AcceptDetail A RIGHT JOIN #TB_MO B ON B.KeyID = A.MO_KeyID

WHERE A.WPID IN (select WPID from BA_v_StandardWPItem where SectionID=36 and IsStat=1) AND  DATEDIFF(DD,A.BillDate , GETDATE()) = 1
GROUP BY A.MO_KeyID) B ON B.MO_KeyID = A.MO_KeyID


-- 更新 #TB_MO  发织数 今日 昨日 累计横机  收货数
UPDATE A SET A.发织数 = B.FQty , A.横机收货数 = B.Qty, A.横机今日收货数 = B.JR, A.横机昨日收货数 = B.ZR FROM #TB_MO A INNER JOIN #TB_HJ B ON B.MO_KeyID
= A.KeyID


------------------------------套口

SELECT
	A.MO_KeyID, 
	SUM(ISNULL(A.Qty, 0)) AS Qty, -- 累计收获
	0 AS JR, -- 今日收获数
	0 AS ZR	-- 昨日收货数
	INTO #TB_TK
FROM 
	dbo.PR_AcceptDetail AS A
	RIGHT JOIN #TB_MO B ON A.MO_KeyID = B.KeyID
WHERE
	A.WPID IN (select WPID from BA_v_StandardWPItem where SectionID=37 and IsStat=1)
GROUP BY
	A.MO_KeyID


--  更新 今日 套口数
UPDATE A  SET A.JR = B.JR FROM #TB_TK A INNER JOIN

(SELECT MO_KeyID,SUM(ISNULL(Qty,0)) AS JR FROM PR_AcceptDetail A RIGHT JOIN #TB_MO B ON B.KeyID = A.MO_KeyID

WHERE A.WPID IN (select WPID from BA_v_StandardWPItem where SectionID=37 and IsStat=1) AND  DATEDIFF(DD,A.BillDate , GETDATE()) = 0
GROUP BY A.MO_KeyID) B ON B.MO_KeyID = A.MO_KeyID

--  更新 昨日 套口数
UPDATE A  SET A.ZR = B.ZR FROM #TB_TK A INNER JOIN

(SELECT MO_KeyID,SUM(ISNULL(Qty,0)) AS ZR FROM PR_AcceptDetail A RIGHT JOIN #TB_MO B ON B.KeyID = A.MO_KeyID

WHERE A.WPID IN (select WPID from BA_v_StandardWPItem where SectionID=37 and IsStat=1) AND  DATEDIFF(DD,A.BillDate , GETDATE()) = 1
GROUP BY A.MO_KeyID) B ON B.MO_KeyID = A.MO_KeyID

-- 更新 套口 数据 
UPDATE A SET A.套口收货数 = B.Qty , A.套口今日收货数 = B.JR, A.套口昨日收货数 = B.ZR FROM #TB_MO A INNER JOIN #TB_TK B ON B.MO_KeyID
= A.KeyID


------------------------------洗水

SELECT
	A.MO_KeyID, 
	SUM(ISNULL(A.Qty, 0)) AS Qty, -- 累计收获
	0 AS JR, -- 今日收获数
	0 AS ZR	-- 昨日收货数
	INTO #TB_XS
FROM 
	dbo.PR_AcceptDetail AS A
	RIGHT JOIN #TB_MO B ON A.MO_KeyID = B.KeyID
WHERE
	A.WPID IN (select WPID from BA_v_StandardWPItem where SectionID=31 and IsStat=1)
GROUP BY
	A.MO_KeyID


--  更新 今日 洗水数
UPDATE A  SET A.JR = B.JR FROM #TB_XS A INNER JOIN

(SELECT MO_KeyID,SUM(ISNULL(Qty,0)) AS JR FROM PR_AcceptDetail A RIGHT JOIN #TB_MO B ON B.KeyID = A.MO_KeyID

WHERE A.WPID IN (select WPID from BA_v_StandardWPItem where SectionID=31 and IsStat=1) AND  DATEDIFF(DD,A.BillDate , GETDATE()) = 0
GROUP BY A.MO_KeyID) B ON B.MO_KeyID = A.MO_KeyID

--  更新 昨日 洗水数
UPDATE A  SET A.ZR = B.ZR FROM #TB_XS A INNER JOIN

(SELECT MO_KeyID,SUM(ISNULL(Qty,0)) AS ZR FROM PR_AcceptDetail A RIGHT JOIN #TB_MO B ON B.KeyID = A.MO_KeyID

WHERE A.WPID IN (select WPID from BA_v_StandardWPItem where SectionID=31 and IsStat=1) AND  DATEDIFF(DD,A.BillDate , GETDATE()) = 1
GROUP BY A.MO_KeyID) B ON B.MO_KeyID = A.MO_KeyID

-- 更新 洗水 数据 
UPDATE A SET A.洗水收货数 = B.Qty , A.洗水今日收货数 = B.JR, A.洗水昨日收货数 = B.ZR FROM #TB_MO A INNER JOIN #TB_XS B ON B.MO_KeyID
= A.KeyID
------------------------------整烫

SELECT
	A.MO_KeyID, 
	SUM(ISNULL(A.Qty, 0)) AS Qty, -- 累计收获
	0 AS JR, -- 今日收获数
	0 AS ZR	-- 昨日收货数
	INTO #TB_ZT
FROM 
	dbo.PR_AcceptDetail AS A
	RIGHT JOIN #TB_MO B ON A.MO_KeyID = B.KeyID
WHERE
	A.WPID IN (select WPID from BA_v_StandardWPItem where SectionID=5 and IsStat=1)
GROUP BY
	A.MO_KeyID


--  更新 今日 整烫数
UPDATE A  SET A.JR = B.JR FROM #TB_ZT A INNER JOIN

(SELECT MO_KeyID,SUM(ISNULL(Qty,0)) AS JR FROM PR_AcceptDetail A RIGHT JOIN #TB_MO B ON B.KeyID = A.MO_KeyID

WHERE A.WPID IN (select WPID from BA_v_StandardWPItem where SectionID=5 and IsStat=1) AND  DATEDIFF(DD,A.BillDate , GETDATE()) = 0
GROUP BY A.MO_KeyID) B ON B.MO_KeyID = A.MO_KeyID

--  更新 昨日 整烫数
UPDATE A  SET A.ZR = B.ZR FROM #TB_ZT A INNER JOIN

(SELECT MO_KeyID,SUM(ISNULL(Qty,0)) AS ZR FROM PR_AcceptDetail A RIGHT JOIN #TB_MO B ON B.KeyID = A.MO_KeyID

WHERE A.WPID IN (select WPID from BA_v_StandardWPItem where SectionID=5 and IsStat=1) AND  DATEDIFF(DD,A.BillDate , GETDATE()) = 1
GROUP BY A.MO_KeyID) B ON B.MO_KeyID = A.MO_KeyID

-- 更新 整烫 数据 
UPDATE A SET A.整烫收货数 = B.Qty , A.整烫今日收货数 = B.JR, A.整烫昨日收货数 = B.ZR FROM #TB_MO A INNER JOIN #TB_ZT B ON B.MO_KeyID
= A.KeyID

------------------------------成检

SELECT
	A.MO_KeyID, 
	SUM(ISNULL(A.Qty, 0)) AS Qty, -- 累计收获
	0 AS JR, -- 今日收获数
	0 AS ZR	-- 昨日收货数
	INTO #TB_CJ
FROM 
	dbo.PR_AcceptDetail AS A
	RIGHT JOIN #TB_MO B ON A.MO_KeyID = B.KeyID
WHERE
	A.WPID IN (select WPID from BA_v_StandardWPItem where SectionID=40 and IsStat=1)
GROUP BY
	A.MO_KeyID


--  更新 今日 成检数
UPDATE A  SET A.JR = B.JR FROM #TB_CJ A INNER JOIN

(SELECT MO_KeyID,SUM(ISNULL(Qty,0)) AS JR FROM PR_AcceptDetail A RIGHT JOIN #TB_MO B ON B.KeyID = A.MO_KeyID

WHERE A.WPID IN (select WPID from BA_v_StandardWPItem where SectionID=40 and IsStat=1) AND  DATEDIFF(DD,A.BillDate , GETDATE()) = 0
GROUP BY A.MO_KeyID) B ON B.MO_KeyID = A.MO_KeyID

--  更新 昨日 成检数
UPDATE A  SET A.ZR = B.ZR FROM #TB_CJ A INNER JOIN

(SELECT MO_KeyID,SUM(ISNULL(Qty,0)) AS ZR FROM PR_AcceptDetail A RIGHT JOIN #TB_MO B ON B.KeyID = A.MO_KeyID

WHERE A.WPID IN (select WPID from BA_v_StandardWPItem where SectionID=40 and IsStat=1) AND  DATEDIFF(DD,A.BillDate , GETDATE()) = 1
GROUP BY A.MO_KeyID) B ON B.MO_KeyID = A.MO_KeyID

-- 更新 成检 数据 
UPDATE A SET A.成检收货数 = B.Qty , A.成检今日收货数 = B.JR, A.成检昨日收货数 = B.ZR FROM #TB_MO A INNER JOIN #TB_CJ B ON B.MO_KeyID
= A.KeyID

------------------------------包装

SELECT
	A.MO_KeyID, 
	SUM(ISNULL(A.Qty, 0)) AS Qty, -- 累计收获
	0 AS JR, -- 今日收获数
	0 AS ZR	-- 昨日收货数
	INTO #TB_BZ
FROM 
	dbo.PR_AcceptDetail AS A
	RIGHT JOIN #TB_MO B ON A.MO_KeyID = B.KeyID
WHERE
	A.WPID IN (select WPID from BA_v_StandardWPItem where SectionID=20 and IsStat=1)
GROUP BY
	A.MO_KeyID


--  更新 今日 包装数
UPDATE A  SET A.JR = B.JR FROM #TB_BZ A INNER JOIN

(SELECT MO_KeyID,SUM(ISNULL(Qty,0)) AS JR FROM PR_AcceptDetail A RIGHT JOIN #TB_MO B ON B.KeyID = A.MO_KeyID

WHERE A.WPID IN (select WPID from BA_v_StandardWPItem where SectionID=20 and IsStat=1) AND  DATEDIFF(DD,A.BillDate , GETDATE()) = 0
GROUP BY A.MO_KeyID) B ON B.MO_KeyID = A.MO_KeyID

--  更新 昨日 包装数
UPDATE A  SET A.ZR = B.ZR FROM #TB_BZ A INNER JOIN

(SELECT MO_KeyID,SUM(ISNULL(Qty,0)) AS ZR FROM PR_AcceptDetail A RIGHT JOIN #TB_MO B ON B.KeyID = A.MO_KeyID

WHERE A.WPID IN (select WPID from BA_v_StandardWPItem where SectionID=20 and IsStat=1) AND  DATEDIFF(DD,A.BillDate , GETDATE()) = 1
GROUP BY A.MO_KeyID) B ON B.MO_KeyID = A.MO_KeyID

-- 更新 包装 数据 
UPDATE A SET A.包装收货数 = B.Qty , A.包装今日收货数 = B.JR, A.包装昨日收货数 = B.ZR FROM #TB_MO A INNER JOIN #TB_BZ B ON B.MO_KeyID
= A.KeyID
*/
-- 更新在制品数据 ---------------------
--  
DECLARE MYCURSOR CURSOR FOR  -- 定义游标
SELECT KeyID FROM #TB_MO			--循环体
OPEN MYCURSOR									--打开游标
FETCH NEXT FROM MYCURSOR INTO @KEYID				--读取首行
WHILE @@FETCH_STATUS = 0		
	BEGIN
		EXEC getRemaining @KEYID, @REMAIN
		UPDATE #TB_MO SET 横机在制品 = ISNULL(@REMAIN,0)
		FETCH NEXT FROM MYCURSOR INTO @KEYID
	END
CLOSE MYCURSOR								--关闭游标
DEALLOCATE MYCURSOR						--释放游标
	--------------------------------------- END
	/*
	SELECT
	MO_KeyID,
	MAX ( BIllDate ) AS RECEDATE
	INTO #TB_TIME
FROM
	[dbo].[PR_v_AcceptDetail] 
WHERE
	WPID = 13 
GROUP BY
	MO_KeyID
	
	-- 订单完成之后48小时 取消显示
SELECT 
A.*,
B.SendMakeQty,
CONVERT(VARCHAR(15),C.RECEDATE,23) AS BZ_S_DATE

  FROM #TB_MO A
	LEFT JOIN (
	SELECT
		MO_KeyID,
		SUM ( ISNULL(Qty, 0) ) AS SendMakeQty 
	FROM
		PR_v_SendDetail 
	WHERE
		WPID IN (select WPID from BA_v_StandardWPItem where SectionID=36 and IsStat=1)  
	GROUP BY
		MO_KeyID 
	) B ON A.KeyID = B.MO_KeyID 
	LEFT JOIN #TB_TIME C ON C.MO_KeyID = A.KeyID 
WHERE A.[包装收货数] < A.[计划数] OR (A.[包装收货数] >= A.[计划数] AND DATEDIFF(DD, C.RECEDATE, GETDATE())<3)

ORDER BY A.KeyID
*/
SELECT * FROM #TB_MO  ORDER BY KeyID-------------------------------------------------------------------------------------------debug
 
 

