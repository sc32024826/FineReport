SET NOCOUNT ON
SELECT A.KeyID,A.MO,A.StyleID,A.TotalQty AS PlanTotalQty,CONVERT(NVARCHAR(50), A.MakeDate, 23) AS MakeDate,CONVERT(NVARCHAR(50), A.ExpireDate, 23) AS ExpireDate,
0 AS HjFQty,--发货数
0 AS HjSQty,0 AS TkSQty,0 AS XsSQty,0 AS ZtSQty,0 AS CjSQty,0 AS BzSQty,--收货数
0 AS HjJSQty,0 AS TkJSQty,0 AS XsJSQty,0 AS ZtJSQty,0 AS CjJSQty,0 AS BzJSQty,--今日收获数
0 AS HjZSQty,0 AS TkZSQty,0 AS XsZSQty,0 AS ZtZSQty,0 AS CjZSQty,0 AS BzZSQty,--昨日收货数
0 AS HjZzpQty,0 AS TkZzpQty,0 AS XsZzpQty,0 AS ZtZzpQty,0 AS CjZzpQty,0 AS BzZzpQty,--在制品
-- 0 AS HjWwcQty,0 AS TkWwcQty,0 AS XsWwcQty,0 AS ZtWwcQty,0 AS CjWwcQty,0 AS BzWwcQty,--未完成
CAST(NULL AS DATETIME) AS ZzDt,CAST(NULL AS DATETIME) AS ZjDt--最早 最晚流转时间
INTO #TB_MO
FROM
	dbo.PR_v_MO A
	WHERE
	A.BillStatusType NOT IN (0,2,3) AND A.StyleID <> 'TEST01'

--更新横机收发数
SELECT IDENTITY(INT,1,1) AS ID,MO_KeyID,BillDate,ISNULL(Qty,0) AS Qty,0 AS FQty,0 AS WcQty,0 AS JSQty,0 AS ZSQty INTO #TB_HJ
  FROM PR_v_AcceptDetail
 WHERE WPID in (select WPID from BA_v_StandardWPItem where SectionID=36 and IsStat=1)  
 --更新收货时间(最早 最近)
 UPDATE A SET A.ZzDt=B.BillDate,A.ZjDt=B.BillDate
   FROM #TB_MO A
 INNER JOIN (SELECT DISTINCT MO_KeyID,BillDate FROM #TB_HJ)B ON A.KeyID=B.MO_KeyID
  --更新发货数
UPDATE A SET A.FQty=B.FQty
  FROM #TB_HJ A
INNER JOIN (SELECT MO_KeyID,SUM(Qty) AS FQty
  FROM PR_v_SendDetail
 WHERE WPID in (select WPID from BA_v_StandardWPItem where SectionID=36 and IsStat=1)  
GROUP BY MO_KeyID)B ON A.MO_KeyID=B.MO_KeyID
--更新今日收货数
UPDATE #TB_HJ SET JSQty=Qty
 WHERE DateDiff(DD,CONVERT(VARCHAR(100), BillDate, 23) ,CONVERT(VARCHAR(100), GETDATE(), 23) )=0
 --更新今日收货数
UPDATE #TB_HJ SET ZSQty=Qty
 WHERE DateDiff(DD,CONVERT(VARCHAR(100), BillDate, 23) ,CONVERT(VARCHAR(100), GETDATE(), 23) )=1

UPDATE A SET A.HjFQty=B.FQty,A.HjSQty=B.SQty,A.HjJSQty=B.HjJSQty,A.HjZSQty=B.HjZSQty
  FROM #TB_MO A
INNER JOIN (SELECT MO_KeyID,FQty,SUM(Qty) AS SQty,SUM(JSQty) AS HjJSQty ,SUM(ZSQty) HjZSQty FROM #TB_HJ GROUP BY MO_KeyID,FQty)B ON A.KeyID=B.MO_KeyID

--更新套口收货数
SELECT IDENTITY(INT,1,1) AS ID,MO_KeyID,BillDate,ISNULL(Qty,0) AS Qty,0 AS JSQty,0 AS ZSQty INTO #TB_TK
  FROM PR_v_AcceptDetail
 WHERE WPID in (select WPID from BA_v_StandardWPItem where SectionID=37 and IsStat=1)  

 UPDATE A SET A.ZjDt=B.BillDate
   FROM #TB_MO A
 INNER JOIN (SELECT DISTINCT MO_KeyID,BillDate FROM #TB_TK)B ON A.KeyID=B.MO_KeyID

UPDATE #TB_TK SET JSQty=Qty
 WHERE DateDiff(DD,CONVERT(VARCHAR(100), BillDate, 23) ,CONVERT(VARCHAR(100), GETDATE(), 23) )=0

UPDATE #TB_TK SET ZSQty=Qty
 WHERE DateDiff(DD,CONVERT(VARCHAR(100), BillDate, 23) ,CONVERT(VARCHAR(100), GETDATE(), 23) )=1
 
UPDATE A SET A.TkSQty=B.SQty,A.TkJSQty=B.TkJSQty,A.TkZSQty=B.TkZSQty
  FROM #TB_MO A
INNER JOIN (SELECT MO_KeyID,SUM(Qty) AS SQty,SUM(JSQty) AS TkJSQty ,SUM(ZSQty) TkZSQty FROM #TB_TK GROUP BY MO_KeyID)B ON A.KeyID=B.MO_KeyID

--更新洗水收货数
SELECT IDENTITY(INT,1,1) AS ID,MO_KeyID,BillDate,ISNULL(Qty,0) AS Qty,0 AS JSQty,0 AS ZSQty INTO #TB_XS
  FROM PR_v_AcceptDetail
 WHERE WPID in (select WPID from BA_v_StandardWPItem where SectionID=31 and IsStat=1)  

 UPDATE A SET A.ZjDt=B.BillDate
   FROM #TB_MO A
 INNER JOIN (SELECT DISTINCT MO_KeyID,BillDate FROM #TB_XS)B ON A.KeyID=B.MO_KeyID

UPDATE #TB_XS SET JSQty=Qty
 WHERE DateDiff(DD,CONVERT(VARCHAR(100), BillDate, 23) ,CONVERT(VARCHAR(100), GETDATE(), 23) )=0

UPDATE #TB_XS SET ZSQty=Qty
 WHERE DateDiff(DD,CONVERT(VARCHAR(100), BillDate, 23) ,CONVERT(VARCHAR(100), GETDATE(), 23) )=1
 
UPDATE A SET A.XsSQty=B.SQty,A.XsJSQty=B.XsJSQty,A.XsZSQty=B.XsZSQty
  FROM #TB_MO A
INNER JOIN (SELECT MO_KeyID,SUM(Qty) AS SQty,SUM(JSQty) AS XsJSQty ,SUM(ZSQty) XsZSQty FROM #TB_XS GROUP BY MO_KeyID)B ON A.KeyID=B.MO_KeyID

--更新整烫收货数
SELECT IDENTITY(INT,1,1) AS ID,MO_KeyID,BillDate,ISNULL(Qty,0) AS Qty,0 AS JSQty,0 AS ZSQty INTO #TB_ZT
  FROM PR_v_AcceptDetail
 WHERE WPID in (select WPID from BA_v_StandardWPItem where SectionID=5 and IsStat=1)  

 UPDATE A SET A.ZjDt=B.BillDate
   FROM #TB_MO A
 INNER JOIN (SELECT DISTINCT MO_KeyID,BillDate FROM #TB_ZT)B ON A.KeyID=B.MO_KeyID

UPDATE #TB_ZT SET JSQty=Qty
 WHERE DateDiff(DD,CONVERT(VARCHAR(100), BillDate, 23) ,CONVERT(VARCHAR(100), GETDATE(), 23) )=0

UPDATE #TB_ZT SET ZSQty=Qty
 WHERE DateDiff(DD,CONVERT(VARCHAR(100), BillDate, 23) ,CONVERT(VARCHAR(100), GETDATE(), 23) )=1
 
UPDATE A SET A.ZtSQty=B.SQty,A.ZtJSQty=B.ZtJSQty,A.ZtZSQty=B.ZtZSQty
  FROM #TB_MO A
INNER JOIN (SELECT MO_KeyID,SUM(Qty) AS SQty,SUM(JSQty) AS ZtJSQty ,SUM(ZSQty) ZtZSQty FROM #TB_ZT GROUP BY MO_KeyID)B ON A.KeyID=B.MO_KeyID

--更新成检收货数
SELECT IDENTITY(INT,1,1) AS ID,MO_KeyID,BillDate,ISNULL(Qty,0) AS Qty,0 AS JSQty,0 AS ZSQty INTO #TB_CJ
  FROM PR_v_AcceptDetail
 WHERE WPID in (select WPID from BA_v_StandardWPItem where SectionID=40 and IsStat=1)  

 UPDATE A SET A.ZjDt=B.BillDate
   FROM #TB_MO A
 INNER JOIN (SELECT DISTINCT MO_KeyID,BillDate FROM #TB_CJ)B ON A.KeyID=B.MO_KeyID

UPDATE #TB_CJ SET JSQty=Qty
 WHERE DateDiff(DD,CONVERT(VARCHAR(100), BillDate, 23) ,CONVERT(VARCHAR(100), GETDATE(), 23) )=0

UPDATE #TB_CJ SET ZSQty=Qty
 WHERE DateDiff(DD,CONVERT(VARCHAR(100), BillDate, 23) ,CONVERT(VARCHAR(100), GETDATE(), 23) )=1
 
UPDATE A SET A.CjSQty=B.SQty,A.CjJSQty=B.CjJSQty,A.CjZSQty=B.CjZSQty
  FROM #TB_MO A
INNER JOIN (SELECT MO_KeyID,SUM(Qty) AS SQty,SUM(JSQty) AS CjJSQty ,SUM(ZSQty) CjZSQty FROM #TB_CJ GROUP BY MO_KeyID)B ON A.KeyID=B.MO_KeyID

--更新包装收货数
SELECT IDENTITY(INT,1,1) AS ID,MO_KeyID,BillDate,ISNULL(Qty,0) AS Qty,0 AS JSQty,0 AS ZSQty INTO #TB_BZ
  FROM PR_v_AcceptDetail
 WHERE WPID in (select WPID from BA_v_StandardWPItem where SectionID=20 and IsStat=1)  

 UPDATE A SET A.ZjDt=B.BillDate
   FROM #TB_MO A
 INNER JOIN (SELECT DISTINCT MO_KeyID,BillDate FROM #TB_BZ)B ON A.KeyID=B.MO_KeyID

UPDATE #TB_BZ SET JSQty=Qty
 WHERE DateDiff(DD,CONVERT(VARCHAR(100), BillDate, 23) ,CONVERT(VARCHAR(100), GETDATE(), 23) )=0

UPDATE #TB_BZ SET ZSQty=Qty
 WHERE DateDiff(DD,CONVERT(VARCHAR(100), BillDate, 23) ,CONVERT(VARCHAR(100), GETDATE(), 23) )=1
 
UPDATE A SET A.BzSQty=B.SQty,A.BzJSQty=B.BzJSQty,A.BzZSQty=B.BzZSQty
  FROM #TB_MO A
INNER JOIN (SELECT MO_KeyID,SUM(Qty) AS SQty,SUM(JSQty) AS BzJSQty ,SUM(ZSQty) BzZSQty FROM #TB_BZ GROUP BY MO_KeyID)B ON A.KeyID=B.MO_KeyID

--更新在制品
UPDATE #TB_MO SET HjZzpQty=PlanTotalQty-HjSQty,TkZzpQty=HjSQty-TkSQty,XsZzpQty=TkSQty-XsSQty,ZtZzpQty=XsSQty-ZtSQty,CjZzpQty=ZtSQty-CjSQty,BzZzpQty=CjSQty-BzSQty
--更新未完成
-- UPDATE #TB_MO SET HjWwcQty=PlanTotalQty-HjSQty,TkWwcQty=PlanTotalQty-TkSQty,XsWwcQty=PlanTotalQty-XsSQty,ZtWwcQty=PlanTotalQty-ZtSQty,CjWwcQty=PlanTotalQty-CjSQty,BzWwcQty=PlanTotalQty-BzSQty

-- 
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


SELECT A.*,B.*,CONVERT(VARCHAR(15),C.RECEDATE,23) AS BZ_S_DATE
  FROM #TB_MO A
	LEFT JOIN (
	SELECT
		MO_KeyID,
		SUM ( Qty ) AS SendMakeQty 
	FROM
		PR_v_SendDetail 
	WHERE
		WPID IN ( SELECT WPID FROM BA_v_StandardWPItem WHERE SectionID = 36 AND IsStat = 1 ) 
	GROUP BY
		MO_KeyID 
	) B ON A.KeyID = B.MO_KeyID 
	LEFT JOIN #TB_TIME C ON C.MO_KeyID = A.KeyID 
WHERE A.BzSQty < A.PlanTotalQty OR (A.BzSQty >= A.PlanTotalQty AND DATEDIFF(DD, C.RECEDATE, GETDATE())<3)


TRUNCATE TABLE #TB_MO
DROP TABLE #TB_MO
TRUNCATE TABLE #TB_HJ
DROP TABLE #TB_HJ
TRUNCATE TABLE #TB_TK
DROP TABLE #TB_TK
TRUNCATE TABLE #TB_XS
DROP TABLE #TB_XS
TRUNCATE TABLE #TB_ZT
DROP TABLE #TB_ZT
TRUNCATE TABLE #TB_CJ
DROP TABLE #TB_CJ
TRUNCATE TABLE #TB_BZ
DROP TABLE #TB_BZ
TRUNCATE TABLE #TB_TIME
DROP TABLE #TB_TIME