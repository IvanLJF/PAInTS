function crop_edges(mask)
%%%acts on int file
%%% mask = 1x4 vector of left,right, top,bottom to mask, 0 or larger
if(mask<0)
disp('mask values must be between 0 and nx,ny. Use full res width/length')
return
end
if(length(mask)~=4)
disp('mask must have 4 values');
return
end

masklft=mask(1);
maskrgt=mask(2);
masktop=mask(3);
maskbot=mask(4);

set_params
load(ts_paramfile);

ndates  = length(dates);
nints   = length(ints);
[nx,ny] = load_rscs(dates(id).slc,'WIDTH','FILE_LENGTH');
newnx   = floor(nx./rlooks)
newny   = floor(ny./alooks);

if(or(or(or(masklft>nx,maskrgt>nx),masktop>ny),maskbot>ny))
disp('masks must be smaller than size of image')
return
end

for l=1:length(rlooks)
  id1=ceil(masklft/rlooks(l)*2);%x2 for cpx files
  id2=floor((newnx(l)-maskrgt/rlooks(l))*2);
  id3=ceil(masktop/alooks(l));
  id4=floor(newny(l)-maskbot/alooks(l));
  for k=1:nints     
    if(exist(ints(k).flatrlk{l},'file'))
      fidi=fopen(ints(k).flatrlk{l},'r');
      fido=fopen([ints(k).flatrlk{l} 'tmp'],'w');
      for j=1:newny(l)
        tmp=fread(fidi,newnx(l)*2,'real*4');
        tmp(1:id1)=0;
        tmp(id2:end)=0;
	if(and(j>=id3,j<=id4))
          fwrite(fido,tmp,'real*4');
        else
          fwrite(fido,zeros(1,newnx(l)*2),'real*4');
        end
      end
      fclose(fido);
      fclose(fidi);
      movefile([ints(k).flatrlk{l} 'tmp'],ints(k).flatrlk{l});
    end
  end
end

