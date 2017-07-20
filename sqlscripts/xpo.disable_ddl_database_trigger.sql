CREATE TRIGGER [disableDrop] 
ON DATABASE 
FOR --DROP_TABLE, 
DROP_FUNCTION, DROP_PROCEDURE,--, DROP_VIEW
DROP_TABLE,     create_table,     alter_table,
create_function,  --alter_function,
create_procedure, --alter_procedure,
DROP_VIEW,      create_view      --alter_view
AS 
DECLARE @data XML
SET @data = EVENTDATA()
DECLARE @schema nvarchar(100)
SET @schema = @data.value('(/EVENT_INSTANCE/SchemaName)[1]', 'nvarchar(100)')
--IF IS_MEMBER ('db_owner') = 0 AND @Schema = 'dbo'
IF user IN ('tssuser','infosysuser')
BEGIN
--RAISERROR ('Only db owner can drop table, function, procedure or view in dbo schema.',10, 1)
RAISERROR ('Only db owner can drop table, function, procedure in dbo schema.',10, 1)
ROLLBACK
END