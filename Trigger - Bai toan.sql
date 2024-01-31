use quanlybenxeNEW;
-- trigger 1: test insert giá vé - tự động cập nhật
-- insert ve
INSERT INTO VE(SOHD,MAVE,MACX,Vitri,Gia) VALUES('HD60','VE00170','CX012',38, 0);
SELECT * FROM VE WHERE MAVE ='VE00167';
-- UPDATE VÉ - ĐỔI MACX
UPDATE VE
SET MACX = 'CX008'
WHERE MAVE ='VE00167';
SELECT * FROM VE WHERE MAVE ='VE00167';

delete from ve where mave ='VE00167';
-- -----------------------------------------------------------------------------------
-- trigger 2:
-- test INSERT VÉ - THANH TIỀN TỰ ĐỘNG CẬP NHẬT
select * from hoadon WHERE SOHD = 'HD61';
INSERT INTO VE(SOHD,MAVE,MACX,Vitri,Gia) VALUES('HD61','VE00170','CX012',38, 0);
INSERT INTO VE(SOHD,MAVE,MACX,Vitri,Gia) VALUES('HD61','VE00169','CX012',37, 0);
INSERT INTO VE(SOHD,MAVE,MACX,Vitri,Gia) VALUES('HD61','VE00168','CX012',36, 0);
select * from hoadon WHERE SOHD = 'HD61';
-- TEST XÓA VÉ - THÀNH TIỀN TỰ ĐỘNG TRỪ ĐI VÉ ĐÃ XÓA
delete from ve where mave ='VE00169';
select * from hoadon WHERE SOHD = 'HD61';
-- ------------------------------------------------------------------------------------
-- trigger 3:
select * from nhanvien;
INSERT INTO NHANVIEN (MANV, TENNV, DCHI, DTHOAI, LUONG, LOAINV, NGAYVL, HANGBL, MAHANG, GIOITINH) VALUES
('NV00033', 'Diễm My', 'Nghệ An', '0125317321', 14000000, 2, '2022-01-05', 'C', 'HX00003', 'Nữ'); -- insert that bai -> trigger dung
UPDATE nhanvien SET hangbl = null WHERE manv = 'NV00026'; -- update that bai -> trigger dung
-- ------------------------------------------------------------------------------------------
-- trigger 4:
select * from nhanvien ;
-- NV00003 - null -> phân công nhân viên bán vé vào chuyến xe -> kq sai (trigger đúng)
INSERT INTO PHANCONG (MANV,  MACX) VALUES ('NV00004', 'CX020');
-- Phân công nhân viên có hạng bằng lái không phù hợp -> trigger báo lỗi sai (đúng)
INSERT INTO PHANCONG (MANV,  MACX) VALUES ('NV00030', 'CX020');
-- NV00016-hangbl = E (nhân viên đã được phân công lái, cập nhật bằng lái nhỏ hơn) -> kq sai (trigger đúng)
update nhanvien 
set hangbl = 'C'
where manv = 'NV00016';
-- -------------------------------------------------------------------------------------------
-- trigger 5: 
-- INSERT VE
INSERT INTO HOADON (SOHD, MAKH, MANV, NGAYDAT, HT_THANHTOAN, THANHTIEN) VALUES
('HD22', 'KH000007', 'NV00006', '2023-06-18', 'Chuyển khoản',0);
INSERT INTO VE (MAVE, MACX, SOHD, GIA, VITRI)
VALUES ('VE00162', 'CX010', 'HD22', 0, 17);
-- UPDATE CX
update CHUYENXE
set NGAYDI = '2023-03-28'
where macx = 'CX012'
-- -------------------------------------------------------------------------------------------------
-- trigger 6:
DELIMITER //
CREATE TRIGGER INSERT_VITRI 
BEFORE INSERT ON VE
FOR EACH ROW
BEGIN
	IF EXISTS (SELECT 1 FROM VE WHERE VITRI = NEW.VITRI) THEN
    	SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Số ghế của chuyến xe này đã tồn tại.';
    END IF;
END//
DELIMITER ;

DELIMITER //
CREATE TRIGGER INSERT_UPVE_VITRI 
BEFORE UPDATE ON VE
FOR EACH ROW
BEGIN
	IF EXISTS (SELECT 1 FROM VE WHERE VITRI = NEW.VITRI) THEN
    	SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Số ghế của chuyến xe này đã tồn tại.';
    END IF;
END//
DELIMITER ;

DROP TRIGGER INSERT_VITRI 
INSERT INTO VE(SOHD,MAVE, MACX,Vitri,Gia) VALUES('HD61','VE00171','CX012',38, 0)

UPDATE VE
SET VITRI = 36
WHERE SOHD = 'HD61'
SELECT * FROM ve WHERE SOHD = 'HD61'
SELECT * FROM HOADON WHERE SOHD = 'HD61'

-- ---------------------------------------------------------------------------------------------------------
-- Select thông tin vé được in ra giao cho khách hàng (gồm thông tin chuyến xe, thông tin khách hàng)
CREATE VIEW ve_info AS
SELECT ve.mave, ve.vitri, table1.*, table2.*, table4.TEN_BENXE_DI, table4.TEN_BENXE_DEN
FROM ve
LEFT JOIN (
    SELECT cx.*
    FROM chuyenxe cx, TUYENXE TX
    WHERE cx.MATUYEN = TX.MATUYEN
) AS table2 ON ve.macx = table2.macx
INNER JOIN (
    SELECT hd.makh, hd.ngaydat, hd.sohd
    FROM hoadon hd
) AS table1 ON table1.sohd = ve.sohd
INNER JOIN (
    SELECT TX.MATUYEN, BXDI.TENBEN AS TEN_BENXE_DI, BXDEN.TENBEN AS TEN_BENXE_DEN
    FROM TUYENXE TX
    JOIN BENXE BXDI ON TX.BENXEDI = BXDI.MABEN
    JOIN BENXE BXDEN ON TX.BENXEDEN = BXDEN.MABEN
) AS table4 ON table4.MATUYEN = table2.MATUYEN;
drop view ve_info;
SELECT * FROM ve_info;
-- -------------------------------------------------------------------------------------------------
-- Tìm số nhân viên theo loại nhân viên của từng hãng xe
SELECT COUNT(nv.manv) AS SoLuongNhanVien, hx.tenhang
FROM nhanvien nv
JOIN hangxe hx ON nv.mahang = hx.mahang
GROUP BY nv.mahang, hx.tenhang
-- -------------------------------------------------------------------------------------------------
-- Procedure: Nhập vào mã tuyến trả về giá của các hãng có tuyến xe đó
DELIMITER //
CREATE PROCEDURE GetPricesByRoute(IN p_MATUYEN VARCHAR(10))
BEGIN
    SELECT XE.MAHANG, HANGXE.TENHANG, CHUYENXE.GIA
    FROM CHUYENXE
    INNER JOIN XE ON CHUYENXE.BIENSO = XE.BIENSO
    INNER JOIN HANGXE ON XE.MAHANG = HANGXE.MAHANG
    WHERE CHUYENXE.MATUYEN COLLATE utf8mb4_unicode_ci = p_MATUYEN COLLATE utf8mb4_unicode_ci;
END //
DELIMITER ;
CALL GetPricesByRoute('MT002');
drop PROCEDURE GetPricesByRoute;
-- -------------------------------------------------------------------------------------------------
-- Procedure: nhập vào mã chuyến xe, tìm tất cả các ghế còn trống còn lại
drop PROCEDURE FindEmptySeats;
CREATE TABLE temp_seats (
  seat INT
) COLLATE utf8mb4_unicode_ci;

DELIMITER //
CREATE PROCEDURE FindEmptySeats(IN P_MACX VARCHAR(20), OUT P_EmptySeats TEXT)
BEGIN
  -- Tạo bảng tạm
  CREATE TEMPORARY TABLE IF NOT EXISTS temp_seats (seat INT) COLLATE utf8mb4_unicode_ci;
  
  -- Xóa dữ liệu cũ trong bảng tạm
  TRUNCATE TABLE temp_seats;
  
  -- Khai báo biến
  SET @p_TotalSeats = 0;
  SET @i = 1;
  SET @p_XE = '';
  
  -- Lấy dữ liệu
  SELECT BIENSO INTO @p_XE
  FROM CHUYENXE
  WHERE MACX = P_MACX;
  
  SELECT VITRI INTO @p_TotalSeats
  FROM LOAIXE
  INNER JOIN XE ON LOAIXE.MALOAI = XE.MALOAI
  WHERE XE.BIENSO = @p_XE;
  
  -- Thực hiện vòng lặp
  WHILE @i <= @p_TotalSeats DO
    IF NOT EXISTS (SELECT * FROM VE WHERE MACX = P_MACX AND VITRI = @i) THEN
      -- Chèn các vị trí ghế trống vào bảng tạm
      INSERT INTO temp_seats (seat) VALUES (@i);
    END IF;
  
    SET @i = @i + 1;
  END WHILE;
  
  -- Lấy danh sách các vị trí ghế từ bảng tạm
  SET P_EmptySeats = (SELECT GROUP_CONCAT(seat) FROM temp_seats);
  
  -- Xóa bảng tạm
  DROP TABLE IF EXISTS temp_seats;
  
END //
DELIMITER ;

CALL FindEmptySeats('CX012', @EmptySeats);
SELECT @EmptySeats AS EmptySeats;
select * from ve where macx='CX012' order by vitri
-- -------------------------------------------------------------------------------------------------
-- Procedure: Cập nhật tự động hạng bằng lái tối thiểu của từng loại xe
DELIMITER //
CREATE PROCEDURE ExampleProc()
BEGIN
   DECLARE ML CHAR(8) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
   DECLARE SG INT ;
   DECLARE done INT DEFAULT FALSE;
   DECLARE LOAIXECURSOR CURSOR FOR SELECT MALOAI, SOGHE FROM LOAIXE;
   DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
   OPEN LOAIXECURSOR;
   REPEAT
      FETCH LOAIXECURSOR INTO ML, SG;
      IF NOT done THEN
         IF SG between 4 AND 9 THEN
            UPDATE LOAIXE SET HANGBL = 'C' WHERE ML = MALOAI;
         ELSEIF SG between 10 AND 30 THEN
            UPDATE LOAIXE SET HANGBL = 'D' WHERE ML = MALOAI;
         ELSEIF SG > 30 THEN
            UPDATE LOAIXE SET HANGBL = 'E' WHERE ML = MALOAI;
         ELSE
		UPDATE LOAIXE SET HANGBL = 'C' WHERE ML = MALOAI;
		END IF;
	end if;
   UNTIL done END REPEAT;
   CLOSE LOAIXECURSOR;
END//
DELIMITER ;
CALL  ExampleProc();
SELECT * FROM LOAIXE;
-- ---------------------------------------------------------------------------------------------------------
-- Procedure: Nhập vào mã chuyến xe trả về danh sách các nhân viên phù hợp để phân công chuyến xe đó (tài xế và phụ lái)
DELIMITER //
CREATE PROCEDURE GetEmployeeAssignment(IN p_MACX VARCHAR(10))
BEGIN
    SELECT loaixe.hangbl AS YEUCAU_BL, nhanvien.*
    FROM CHUYENXE
    INNER JOIN XE ON CHUYENXE.BIENSO = XE.BIENSO
    INNER JOIN LOAIXE ON XE.MALOAI = LOAIXE.MALOAI
    INNER JOIN NHANVIEN ON NHANVIEN.MAHANG = XE.MAHANG
    WHERE CHUYENXE.macx COLLATE utf8mb4_unicode_ci = p_MACX COLLATE utf8mb4_unicode_ci
        AND (
             (NHANVIEN.LOAINV = 1 AND NHANVIEN.HANGBL COLLATE utf8mb4_unicode_ci >= loaixe.hangbl COLLATE utf8mb4_unicode_ci)
            OR NHANVIEN.LOAINV = 2
        );
END //
DELIMITER ;
CALL GetEmployeeAssignment('CX013');
drop PROCEDURE GetEmployeeAssignment