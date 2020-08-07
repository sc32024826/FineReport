SET NOCOUNT ON
SELECT 
	A.KeyID,
	A.MO,
	A.StyleID,
	CAST('' AS NVARCHAR(2000)) AS DeptName,
	ISNULL(A.TotalQty,0) + ISNULL(B.TotalQty, 0) AS PlanTotalQty,
	CONVERT(NVARCHAR(50), A.MakeDate, 23) AS MakeDate,
	CONVERT(NVARCHAR(50), A.ExpireDate, 23) AS ExpireDate,
	0 AS HjFQty,--发货数
	0 AS HjSQty,0 AS TkSQty,0 AS XsSQty,0 AS ZtSQty,0 AS CjSQty,0 AS BzSQty,--收货数
	0 AS HjZzpQty,0 AS TkZzpQty,0 AS XsZzpQty,0 AS ZtZzpQty,0 AS CjZzpQty,0 AS BzZzpQty,--在制品
	0 AS HjWwcQty,0 AS TkWwcQty,0 AS XsWwcQty,0 AS ZtWwcQty,0 AS CjWwcQty,0 AS BzWwcQty,--未完成
	CAST(NULL AS DATETIME) AS ZzDt,CAST(NULL AS DATETIME) AS ZjDt,--最早 最晚流转时间
	CAST(0.00 AS DECIMAL(10,4)) AS JD,CAST(0.00 AS DECIMAL(10,4)) AS TimeJD,--进度 时间进度
	0 AS CSID
INTO #TB_MO
 FROM dbo.PR_v_MO A 
 LEFT JOIN PR_SendBill B ON A.KeyID = B.MO_KeyID AND B.SectionID = 36 AND B.BillType = 5
WHERE  
	A.BillStatusType NOT IN (0,2,3) 
	AND 
	A.KeyID <> 703
-- SELECT * FROM #TB_MO

--更新横机收发数
SELECT 
	IDENTITY(INT,1,1) AS ID,
	MO_KeyID,
	BillDate,
	ISNULL(Qty,0) AS Qty,
	0 AS FQty 
	INTO #TB_HJ
FROM PR_v_AcceptDetail
WHERE WPID in (select WPID from BA_v_StandardWPItem where SectionID = 36 and IsStat = 1)  
  --更新发货数
UPDATE A SET A.FQty = B.FQty
  FROM #TB_HJ A
INNER JOIN (SELECT MO_KeyID,SUM(Qty) AS FQty
  FROM PR_v_SendDetail
 WHERE WPID in (select WPID from BA_v_StandardWPItem where SectionID = 36 and IsStat = 1)  
GROUP BY MO_KeyID)B ON A.MO_KeyID = B.MO_KeyID
  --更新部门
UPDATE A SET A.DeptName = B.DeptName
  FROM #TB_MO A
INNER JOIN (SELECT DISTINCT MO_KeyID,DeptName FROM PR_v_SendDetail WHERE WPID in (select WPID from BA_v_StandardWPItem where SectionID = 36 and IsStat = 1) )B ON A.KeyID = B.MO_KeyID

UPDATE A SET A.HjFQty = B.FQty,A.HjSQty = B.SQty
  FROM #TB_MO A
INNER JOIN (SELECT MO_KeyID,FQty,SUM(Qty) AS SQty FROM #TB_HJ GROUP BY MO_KeyID,FQty)B ON A.KeyID = B.MO_KeyID

--更新套口收货数
SELECT IDENTITY(INT,1,1) AS ID,MO_KeyID,BillDate,ISNULL(Qty,0) AS Qty INTO #TB_TK
  FROM PR_v_AcceptDetail
 WHERE WPID in (select WPID from BA_v_StandardWPItem where SectionID = 37 and IsStat = 1)  
 
UPDATE A SET A.TkSQty = B.SQty
  FROM #TB_MO A
INNER JOIN (SELECT MO_KeyID,SUM(Qty) AS SQty FROM #TB_TK GROUP BY MO_KeyID)B ON A.KeyID = B.MO_KeyID

--更新洗水收货数
SELECT IDENTITY(INT,1,1) AS ID,MO_KeyID,BillDate,ISNULL(Qty,0) AS Qty INTO #TB_XS
  FROM PR_v_AcceptDetail
 WHERE WPID in (select WPID from BA_v_StandardWPItem where SectionID = 31 and IsStat = 1)  
 
UPDATE A SET A.XsSQty = B.SQty
  FROM #TB_MO A
INNER JOIN (SELECT MO_KeyID,SUM(Qty) AS SQty FROM #TB_XS GROUP BY MO_KeyID)B ON A.KeyID = B.MO_KeyID

--更新整烫收货数
SELECT IDENTITY(INT,1,1) AS ID,MO_KeyID,BillDate,ISNULL(Qty,0) AS Qty INTO #TB_ZT
  FROM PR_v_AcceptDetail
 WHERE WPID in (select WPID from BA_v_StandardWPItem where SectionID = 5 and IsStat = 1)  
 
UPDATE A SET A.ZtSQty = B.SQty
  FROM #TB_MO A
INNER JOIN (SELECT MO_KeyID,SUM(Qty) AS SQty FROM #TB_ZT GROUP BY MO_KeyID)B ON A.KeyID = B.MO_KeyID

--更新成检收货数
SELECT IDENTITY(INT,1,1) AS ID,MO_KeyID,BillDate,ISNULL(Qty,0) AS Qty INTO #TB_CJ
  FROM PR_v_AcceptDetail
 WHERE WPID in (select WPID from BA_v_StandardWPItem where SectionID = 40 and IsStat = 1)  
 
UPDATE A SET A.CjSQty = B.SQty
  FROM #TB_MO A
INNER JOIN (SELECT MO_KeyID,SUM(Qty) AS SQty FROM #TB_CJ GROUP BY MO_KeyID)B ON A.KeyID = B.MO_KeyID

--更新包装收货数
SELECT IDENTITY(INT,1,1) AS ID,MO_KeyID,BillDate,ISNULL(Qty,0) AS Qty INTO #TB_BZ
  FROM PR_v_AcceptDetail
 WHERE WPID in (select WPID from BA_v_StandardWPItem where SectionID = 20 and IsStat = 1)  
 
UPDATE A SET A.BzSQty = B.SQty
  FROM #TB_MO A
INNER JOIN (SELECT MO_KeyID,SUM(Qty) AS SQty FROM #TB_BZ GROUP BY MO_KeyID)B ON A.KeyID = B.MO_KeyID

--更新在制品
UPDATE #TB_MO SET HjZzpQty = PlanTotalQty-HjSQty,TkZzpQty = HjSQty-TkSQty,XsZzpQty = TkSQty-XsSQty,ZtZzpQty = XsSQty-ZtSQty,CjZzpQty = ZtSQty-CjSQty,BzZzpQty = CjSQty-BzSQty
--更新未完成
UPDATE #TB_MO SET HjWwcQty = PlanTotalQty-HjSQty,TkWwcQty = PlanTotalQty-TkSQty,XsWwcQty = PlanTotalQty-XsSQty,ZtWwcQty = PlanTotalQty-ZtSQty,CjWwcQty = PlanTotalQty-CjSQty,BzWwcQty = PlanTotalQty-BzSQty

 --更新收货时间(最早 最近)
 UPDATE A SET A.ZzDt = B.MinBillDate,A.ZjDt = B.MaxBillDate
   FROM #TB_MO A
 INNER JOIN (SELECT DISTINCT MO_KeyID,MIN(BillDate) AS MinBillDate,MAX(BillDate) AS MaxBillDate FROM PR_v_AcceptDetail GROUP BY MO_KeyID)B ON A.KeyID = B.MO_KeyID

--创建权重合计表
CREATE TABLE #TB_Sec(
  ID INT IDENTITY(1,1) NOT NULL,
	SecID INT,
	Coeffient INT,
	PRIMARY KEY(ID)

);

INSERT INTO #TB_Sec VALUES(36,35)
INSERT INTO #TB_Sec VALUES(37,25)
INSERT INTO #TB_Sec VALUES(31,15)
INSERT INTO #TB_Sec VALUES(5,13)
INSERT INTO #TB_Sec VALUES(40,8)
INSERT INTO #TB_Sec VALUES(20,4)

UPDATE A SET A.JD = CAST((A.HjSQty*35+A.TkSQty*25+A.XsSQty*15+A.ZtSQty*13+A.CjSQty*8+A.BzSQty*4) AS DECIMAL(10,4))/(A.PlanTotalQty*B.SCoeffient)
  FROM #TB_MO A
 INNER JOIN (SELECT A.KeyID,SUM(A.Selected*B.Coeffient) AS SCoeffient
  FROM PR_WorkshopSectionPlan A
INNER JOIN (SELECT * FROM #TB_Sec)B ON A.SectionID = B.SecID
 WHERE SectionID IN (5,20,31,36,37,40)
GROUP BY A.KeyID)B ON A.KeyID = B.KeyID

UPDATE A SET A.TimeJD = CAST(NULLIF((DateDiff(DD,A.MakeDate ,CONVERT(VARCHAR(100), GETDATE(), 23))),0) AS DECIMAL(10,4))/(DateDiff(DD,A.MakeDate,A.ExpireDate))
  FROM #TB_MO A

UPDATE A SET A.CSID = B.CSID
  FROM #TB_MO A
INNER JOIN (SELECT KeyID,COUNT(SectionID) AS CSID
  FROM PR_WorkshopSectionPlan
 WHERE SectionID IN (5,20,31,36,37,40) AND Selected = 0
GROUP BY KeyID)B ON A.KeyID = B.KeyID

SELECT 
CASE 
	WHEN DateDiff(DD,ExpireDate,CONVERT(VARCHAR(100), GETDATE(), 23) )>0 AND HjFQty<>0 THEN '超期预警' 
	ELSE CASE WHEN JD = 0 THEN '等待投产' 
	ELSE CASE WHEN JD/TimeJD < 0.8 THEN '进度异常' 
	ELSE CASE WHEN JD > =  1 THEN '待入库' 
	ELSE '正常'
	END 
	END 
	END
END 
ProName,
* INTO #TB_FMO
FROM #TB_MO

--  插入 待发货 数据
INSERT INTO #TB_FMO
EXEC SC_GETREPERTORY
------------START 已经发货数据-------------
SELECT
	A.VatNo,
	CAST ( SUM ( A.InputQty ) AS INT ) AS Qty 
	INTO #TB_HAVESEND -- 已经发货数的临时表
FROM
	dbo.SU_v_MaterialStockDetail_Out AS A 
	RIGHT JOIN SU_MaterialStockBill B ON B.KeyID = A.KeyID AND B.IOType = 2
GROUP BY
	A.VatNo
-------------END ------------
SELECT 
	A.ProName AS '项目名称',
	A.MO AS '生产单号',
	A.StyleID AS '款式名称',
	A.DeptName AS '生产部门',
	A.PlanTotalQty AS '订单数量',
	A.MakeDate,
	A.ExpireDate,
	CONVERT(VARCHAR(15),A.ZjDt,23) AS ZjDt,
	CASE A.ProName
	WHEN '待发货' THEN CAST(ISNULL(B.Qty, 0)/ CAST(A.PlanTotalQty AS FLOAT)AS DECIMAL(5,4)) 
	ELSE A.JD 
	END AS JD,
	A.TimeJD,
	B.Qty
FROM #TB_FMO A
LEFT JOIN #TB_HAVESEND B ON B.VatNo = A.MO 
ORDER BY 
 CHARINDEX(','+A.ProName+',',',超期预警,进度异常,正常,等待投产,待入库,待发货,'),
 A.ExpireDate 

TRUNCATE TABLE #TB_FMO
DROP TABLE #TB_FMO
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
TRUNCATE TABLE #TB_Sec
DROP TABLE #TB_Sec	
TRUNCATE TABLE #TB_HAVESEND
DROP TABLE #TB_HAVESEND