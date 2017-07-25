/*===================================================
Adolfo Q.
===================================================*/

UPDATE Printer 
SET NetworkPrinterName = '\\Prueba1\Laser3'


-- UPDATE ApplicationSetting 
-- SET Value = '\\TssPlsWeb1\BackOffice.FilesRepository'
-- WHERE GroupName = 'File Server' AND Name= 'FileServerPath'


UPDATE ApplicationSetting
 SET Value='\\PLSQUTL01\BackOffice.FilesRepository'
WHERE GroupName='File Server'
 AND Name='FileServerPath'; 

UPDATE ApplicationSetting 
SET Value = 'plsboadmin@tss.com.pe'
WHERE GroupName = 'LineHaul' AND Name= 'LineHaulServer'
 
UPDATE ApplicationSetting 
SET Value = 'plsboadmin@tss.com.pe'
WHERE GroupName = 'Work Order' AND Name= 'RailBillingEmail'
 

UPDATE PLSUser 
SET Email = 'PLSBOADMIN@TSS.COM.PE', Phone = '4405010', Fax = '4405010'
 
UPDATE BPAddress
SET FaxNo ='4405010', Email = 'PLSBOADMIN@TSS.COM.PE'
 
UPDATE BPContact
SET FaxNo = '4405010', Email = 'PLSBOADMIN@TSS.COM.PE'
 
UPDATE InternalContact
SET FaxNo = '4405010', Email = 'PLSBOADMIN@TSS.COM.PE'
 
--UPDATE WorkOrderPartner
--SET TelephoneNo = '4405010', FaxNo = '4405010', Email = 'PLSBOADMIN@TSS.COM.PE'
 

 UPDATE WorkOrderPartner  SET 
	TelephoneNo = CASE WHEN TelephoneNo IS NOT NULL THEN '4405010' ELSE NULL END,  
	FaxNo		= CASE WHEN FAXNO IS NOT NULL THEN '4405010' ELSE NULL END, 
	Email		= CASE WHEN Email IS NOT NULL THEN 'PLSBOADMIN@TSS.COM.PE' ELSE NULL END
	


 
--UPDATE CustomerOrderPartner  
--SET TelephoneNo = '4405010', FaxNo = '4405010', Email = 'PLSBOADMIN@TSS.COM.PE'

 UPDATE CustomerOrderPartner  SET 
	TelephoneNo = CASE WHEN TelephoneNo IS NOT NULL THEN '4405010' ELSE NULL END,  
	FaxNo		= CASE WHEN FAXNO IS NOT NULL THEN '4405010' ELSE NULL END, 
	Email		= CASE WHEN Email IS NOT NULL THEN 'PLSBOADMIN@TSS.COM.PE' ELSE NULL END

 
 
UPDATE QuotePartner 
SET TelephoneNo = '4405010', FaxNo = '4405010', Email = 'PLSBOADMIN@TSS.COM.PE'
 
UPDATE Site
SET Email = 'plsboadmin@tss.com.pe', TelephoneNo = '4405010', FaxNo = '4405010'


update ApplicationSetting 
  set Value =''
WHERE GroupName = 'CustomerInvoice'
and Name ='DefaultPrinter'
 
---------


--use plsconfig
--Delete UserAlert

--delete alert



---------


--Edi 
-- update  SystemSetting  set Value='T'
-- where groupname='environment'
-- and Code='environment'


-- Para habilitar los usuairos de tss
update s set s.status ='1'
from PLSUser s 
where UserName in ('pilar.garcia','SILVIA.VALDIVIA',
'margarita.marchino','miguel.anastacio','patricia.yep','paul.romero1' )




--- David 
DECLARE @RetailCompanyId INT
DECLARE @RetailBusinessPartnerId INT
DECLARE @EDIUserId INT
DECLARE @EDIRoleId int
DECLARE @RoleName VARCHAR(50)='Application Administration'
DECLARE @UserCompanyId INT
DECLARE @UserCompanyRoleId INT

--UPDATE BusinessPartner SET Code='C020' WHERE Code='C020C'
--SELECT @RetailBusinessPartnerId=BusinessPartnerId FROM BusinessPartner WHERE Code='C020'
--UPDATE Company SET BusinessPartnerId=(@RetailBusinessPartnerId) WHERE Code='C020'

SELECT @RetailCompanyId=CompanyId FROM Company WHERE Code='C020C'
SELECT @EDIUserId=UserId FROM PLSUser WHERE UserName='plsediadmin'
SELECT @EDIRoleId=RoleId FROM Role WHERE Name=@RoleName


if (@RetailCompanyId is not null)
begin
	IF NOT EXISTS(SELECT 1 FROM UserCompany WHERE CompanyId=@RetailCompanyId AND UserId=@EDIUserId)
	BEGIN
		EXECUTE spuSystemIndexGetId 'UserCompany',1, @UserCompanyId OUTPUT
		INSERT INTO UserCompany (UserCompanyId, CompanyId, UserId, IsDefaultCompany, CreatedBy, CreationDate, UpdatedBy, UpdateDate)
		VALUES (@UserCompanyId, @RetailCompanyId, @EDIUserId, '0', 'SYSADMIN', getdate(), 'SYSADMIN', getdate())
	END

	IF NOT EXISTS(SELECT 1 FROM UserCompanyRole WHERE UserCompanyId=@UserCompanyId AND RoleId=@EDIRoleId)
	BEGIN
		EXECUTE spuSystemIndexGetId 'UserCompanyRole',1, @UserCompanyRoleId OUTPUT
		INSERT INTO dbo.UserCompanyRole (UserCompanyRoleId, RoleId, UserCompanyId, CreatedBy, CreationDate, UpdatedBy, UpdateDate)
		VALUES (@UserCompanyRoleId, @EDIRoleId, @UserCompanyId, 'SYSADMIN', getdate(), 'SYSADMIN', getdate())
	END
end






declare @companyid int
declare @id int

select @companyid = CompanyId
  from Company
where Code = 'C020'


if (@companyid is not null)
begin
  if not exists (select * from SystemIndex where TableName = 'ApplicationDocumentNumber')
  begin
    insert into SystemIndex select 'ApplicationDocumentNumber', 0;
  end    

  if not exists(select 1 from ApplicationDocumentNumber where CompanyId=@companyid and EntityCode='CO')
  begin  
    exec dbo.spuSystemIndexGetId 'ApplicationDocumentNumber', 1, @id out
                                
    insert into ApplicationDocumentNumber
               (ApplicationDocumentNumberId
               , CompanyId
               , EntityCode
               , Prefix
               , Sequence
               , LengthMax
               , InitialSequence
               , FinalSequence
               )
               values
               (
                @id
                , @companyid
                , 'CO'
                , 'CO'
                , 0
                , 7
                , 0
                , 9999999
               )
    end
                
    if not exists(select 1 from ApplicationDocumentNumber where CompanyId=@companyid and EntityCode='WO')
    begin 
                                exec dbo.spuSystemIndexGetId 'ApplicationDocumentNumber', 1, @id out
                                
                                insert into ApplicationDocumentNumber
                                (
                                ApplicationDocumentNumberId
                                , CompanyId
                                , EntityCode
                                , Prefix
                                , Sequence
                                , LengthMax
                                , InitialSequence
                                , FinalSequence
                                )
                                values
                                (
                                @id
                                , @companyid
                                , 'WO'
                                , 'WO'
                                , 0
                                , 7
                                , 0
                                , 9999999
                                )
   end
end


SET @companyid = null
SET @id = null

select @companyid = CompanyId
  from Company
where Code = 'C020'


if (@companyid is not null)
begin
    if not exists(select 1 from ApplicationDocumentNumber where CompanyId=@companyid and EntityCode='DL')
    begin  
         exec dbo.spuSystemIndexGetId 'ApplicationDocumentNumber', 1, @id out
         insert into ApplicationDocumentNumber
                    (ApplicationDocumentNumberId
                                                                                                , CompanyId
                                                                                                , EntityCode
                                                                                                , Prefix
                                                                                                , Sequence
                                                                                                , LengthMax
                                                                                                , InitialSequence
                                                                                                , FinalSequence
                                                                                                )
                                                                                                values
                                                                                                (
                                                                                                @id
                                                                                                , @companyid
                                                                                                , 'DL'
                                                                                                , 'DL'
                                                                                                , 0
                                                                                                , 8
                                                                                                , 0
                                                                                                , 99999999
                                                                                                )
   end                                                             
end



SET @companyid = NULL
SET @id = NULL

select @companyid = CompanyId
  from Company
where Code = 'C020'


if (@companyid is not null)
begin
    if not exists(select 1 from ApplicationDocumentNumber where CompanyId=@companyid and EntityCode='DR')
    begin  
         exec dbo.spuSystemIndexGetId 'ApplicationDocumentNumber', 1, @id out
         insert into ApplicationDocumentNumber
                    ( ApplicationDocumentNumberId
                    , CompanyId
                    , EntityCode
                    , Prefix
                    , Sequence
                    , LengthMax
                    , InitialSequence
                    , FinalSequence
                    )
              values
                    ( @id
                    , @companyid
                    , 'DR'
                    , 'DR'
                    , 0
                    , 8
                    , 0
                    , 99999999
                    )
    end                                                             
end



--En PLS
update sitecontact set Email ='PLSBOADMIN@TSS.COM.PE'
--o	Considerando que el Site pertenezca a ERS

update metroareacontact set Email ='PLSBOADMIN@TSS.COM.PE' WHERE Email <>'PLSBOADMIN@TSS.COM.PE'

update reservationorder set AdditionalContactEmail  ='PLSBOADMIN@TSS.COM.PE',
			    AdditionalContactEmail2 ='PLSBOADMIN@TSS.COM.PE'


update bpnotification 
set NotificationValue  =
		case CommunicationMethodCode when 'E' then   'PLSBOADMIN@TSS.COM.PE' 
									 when 'M' then   'PLSBOADMIN@TSS.COM.PE' 
									 when 'F' then   '4405010'
		end
where CommunicationMethodCode in ('E','M','F')


--2015/04/28
update c set BCCMail  ='PLSBOADMIN@TSS.COM.PE'	       FROM CustomerOrderExceptionEmail C WHERE  BCCMail <>'PLSBOADMIN@TSS.COM.PE'
update c set CCMail  ='PLSBOADMIN@TSS.COM.PE'	       FROM CustomerOrderExceptionEmail C WHERE  CCMail <>'PLSBOADMIN@TSS.COM.PE'
update c set ContactEmail  ='PLSBOADMIN@TSS.COM.PE'    FROM OrderStop C WHERE  ContactEmail NOT IN ('PLSBOADMIN@TSS.COM.PE')
update c set ContactFaxNo  ='4405010'                  FROM OrderStop C WHERE  ContactFaxNo NOT IN ('4405010')

update c set Email  ='PLSBOADMIN@TSS.COM.PE'	       FROM CustomerOrderCargoCommodityContact C WHERE  Email NOT IN ('PLSBOADMIN@TSS.COM.PE','')
update c set Email  ='PLSBOADMIN@TSS.COM.PE'           FROM WorkOrderCargoCommodityContact C WHERE  Email NOT IN ('PLSBOADMIN@TSS.COM.PE','')
update c set Email  ='PLSBOADMIN@TSS.COM.PE'           FROM OrderStopContact C WHERE  Email NOT IN ('PLSBOADMIN@TSS.COM.PE','')
update c set Email  ='PLSBOADMIN@TSS.COM.PE'           FROM FunctionalGroupUser C WHERE  Email NOT IN ('PLSBOADMIN@TSS.COM.PE','')
update c set FromMail  ='PLSBOADMIN@TSS.COM.PE'        FROM CustomerOrderExceptionEmail C WHERE  FromMail NOT IN ('PLSBOADMIN@TSS.COM.PE','')
update c set IMCEmailAddress  ='PLSBOADMIN@TSS.COM.PE' FROM WPAParentChild C WHERE  IMCEmailAddress NOT IN ('PLSBOADMIN@TSS.COM.PE','')
update c set ToMail  ='PLSBOADMIN@TSS.COM.PE' FROM CustomerOrderExceptionEmail C WHERE  ToMail NOT IN ('PLSBOADMIN@TSS.COM.PE','')



--ALTER DATABASE DB_NAME SET NEW_BROKER WITH ROLLBACK IMMEDIATE;---pls
-- cOLAS

--HABILITAR COLAS PARA PWB
Declare @w nvarchar(max)
set @w = 'ALTER DATABASE ' + db_name() + ' SET NEW_BROKER  WITH rollback immediate '
execute sp_executesql @w


DELETE FROM es.ServiceBrokerConversations


update ReservationOrder set AdditionalContactFax='4405010'  where AdditionalContactFax is not null and AdditionalContactFax<>'4405010'

/*===================================================
Michael V.
===================================================*/

-- Added by Kiefer
UPDATE ApplicationSetting
SET Value = ''
where Name = 'QuoteLaneRouteEmailAddress'

update apsc
set Value = ''
from ApplicationSetting aps INNER JOIN ApplicationSettingCompany apsc
on aps.ApplicationSettingId = apsc.ApplicationSettingId
where Name = 'QuoteLaneRouteEmailAddress'
