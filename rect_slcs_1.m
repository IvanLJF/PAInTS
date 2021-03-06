set_params
load(ts_paramfile);
ndates  = length(dates);
initoff = 50; %this was used in read_dopbase to shift the master date backwards 
rangepx = load_rscs(dates(id).raw,'RANGE_PIXEL_SIZE');
lambda  = load_rscs(dates(id).raw,'WAVELENGTH');
[dop0,dop1,dop2,dop3,azres,squint]=load_rscs('all.dop.rsc','DOPPLER_RANGE0','DOPPLER_RANGE1','DOPPLER_RANGE2','DOPPLER_RANGE3','AZIMUTH_RESOLUTION','SQUINT');

copyfile([dates(id).slc '.rsc'],[dates(id).rectslc '.rsc']);
dates(id).aff=[1 0 1 0 0 0];

[nx1,ny1]=load_rscs(dates(id).slc,'WIDTH','FILE_LENGTH');
for i=[1:id-1 id+1:ndates] %skips the id date
    [nx2,ny2]=load_rscs(dates(i).slc,'WIDTH','FILE_LENGTH');
    
    offname=[rectdir 'rectfiles/' dates(i).name];
    if(~exist([offname '_fitoff.out']))
        command=['$INT_SCR/offset.pl ' dates(id).slc ' ' dates(i).slc ' ' offname ' 2 cpx ' num2str([dates(i).rgoff initoff noff noff offwin searchwin])];
        mysys(command);
        command=['$MY_BIN/fitoff_quad ' offname '.off ' offname '_cull.off 1.5 0.5 50 > ' offname '_fitoff.out'];
        mysys(command);
    end
end

if(plotflag)
    %check offsets
    f1 = figure('Name','X Offsets');
    f2 = figure('Name','Y Offsets');
    a  = floor(sqrt(ndates));
    b  = ceil(ndates/a);
    ax = [1 nx1 1 ny1];
    for i=[1:id-1 id+1:ndates]
        tmp=load([rectdir 'rectfiles/' dates(i).name '_cull.off']);
        figure(f1);
        subplot(a,b,i)
        scatter(tmp(:,1),tmp(:,3),12,tmp(:,2),'filled');
        axis(ax);
        colorbar('h')
        title(dates(i).name)
        figure(f2);
        subplot(a,b,i)
        scatter(tmp(:,1),tmp(:,3),12,tmp(:,4),'filled');
        axis(ax);
        colorbar('h')
        title(dates(i).name)
    end
end
%return
%Run rect
for i=[1:id-1 id+1:ndates]
    if(~exist(dates(i).rectslc))
        command=['grep WARNING ' offname '_fitoff.out'];
        [status,result]=mysys(command);
        offname=[rectdir 'rectfiles/' dates(i).name];
        
        
        if(status)
            command=['$OUR_SCR/find_affine_quad.pl ' offname '_fitoff.out'];
            [junk,aff]=mysys(command);
            aff=str2num(aff);
            
            resampin=[rectdir 'rectfiles/resamp_' dates(i).name '.in'];
            fid=fopen(resampin,'w');
            fprintf(fid,'Image Offset File Name                      (-)     = %s\n',[offname '_cull.off']);
            fprintf(fid,'Display Fit Statistics to Screen                        (-)     = No Fit Stats\n');
            fprintf(fid,'Number of Fit Coefficients                              (-)     = 6\n');
            fprintf(fid,'SLC Image File 1                                        (-)     = %s\n',dates(id).slc);
            fprintf(fid,'Number of Range Samples Image 1                         (-)     = %d\n',nx1);
            fprintf(fid,'SLC Image File 2                                        (-)     = %s\n',dates(i).slc);
            fprintf(fid,'Number of Range Samples Image 2                         (-)     = %d\n',nx2);
            fprintf(fid,'Starting Line, Number of Lines, and First Line Offset   (-)     = 1 %d 1\n',ny1);
            fprintf(fid,'Doppler Cubic Fit Coefficients - PRF Units              (-)     = %12.8g %12.8g %12.8g 0\n',dop0,dop1,dop2);
            fprintf(fid,'Radar Wavelength                                        (m)     = %12.8g\n',lambda);
            fprintf(fid,'Slant Range Pixel Spacing                               (m)     = %12.8g\n',rangepx);
            fprintf(fid,'Number of Range and Azimuth Looks                       (-)     = 1 1\n');
            fprintf(fid,'Flatten with offset fit?                                (-)     = No \n');
            fprintf(fid,'Resampled SLC 1 File                                    (-)     = %s\n',dates(id).rectslc);
            fprintf(fid,'Resampled SLC 2 File                                    (-)     = %s\n',dates(i).rectslc);
            fprintf(fid,'Output Interferogram File                               (-)     = jnkint\n');
            fprintf(fid,'Multi-look Amplitude File                               (-)     = jnkamp\n');
            fprintf(fid,'END\n');
            fclose(fid);
            
            command=['$MY_BIN/resamp_roi_nofilter ' resampin];
            mysys(command);
            copyfile([dates(i).slc '.rsc'],[dates(i).rectslc '.rsc']);
            command=['$INT_SCR/use_rsc.pl ' dates(i).rectslc ' write WIDTH ' num2str(nx1)];
            mysys(command);
            command=['$INT_SCR/use_rsc.pl ' dates(i).rectslc ' write FILE_LENGTH ' num2str(ny1)];
            mysys(command);
            dates(i).aff=aff;
        else
            disp(result)
        end
    end
end
if(exist('ints','var'))
    save(ts_paramfile,'dates','ints');
else
    save(ts_paramfile,'dates');
end
