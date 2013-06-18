alter table mime_types add extension text not null;
insert into mime_types (mime_type, extension) values ('image/jpeg', 'jpeg');
