clear
close all;
dataDir = '/mnt/bic/internal/MRIL/Yuhui_Chai/LayMovie';

cd(dataDir)

subj_list=dir(['group/All_Surfmeannew/SUMA/hub/function_connectivity_map_xxx.both.1D.dset']);

for subj_ind=1:length(subj_list)
	if rem(subj_ind,6)==0
		close all;
	end
	cd(subj_list(subj_ind).folder);
	dset_file=subj_list(subj_ind).name;

	outputNm = ['K2.' dset_file];
	if isfile(outputNm)<1

	fprintf('++ Begin analyzing %s in %s ... \n',subj_list(subj_ind).name,subj_list(subj_ind).folder);

	mask_file=['../Surf.RefMeanAll.both.brain_mask.1D.dset'];


	dset=load(dset_file);
	mask1=load(mask_file);

	sd_dset=std(dset,[],2);
	mask_sd=(sd_dset>1e-10);
	mask1=mask1.*mask_sd;		

	[~,layerNum]=size(dset);
	layer=[0:layerNum-1]/(layerNum-1);

	mask2=zeros(size(dset));
	mask2=(dset~=0);

	mask=mask1.*mask2(:,1).*mask2(:,2).*mask2(:,3).*mask2(:,4).*mask2(:,5).*mask2(:,6).*mask2(:,7).*mask2(:,8).*mask2(:,9).*mask2(:,10) ...
		.*mask2(:,11).*mask2(:,12).*mask2(:,13).*mask2(:,14).*mask2(:,15).*mask2(:,16).*mask2(:,17).*mask2(:,18);

	index=find(mask>0);
	dset_fit=dset(index,:);

	sd_fit=std(dset_fit,[],2);
	sdmin=min(sd_fit(:));
	fprintf('++ sdmin = %f ... \n',sdmin);

	% kmeans
	K_num = 2:2;
	Km_cr = zeros(length(index),length(K_num));

	for K_ind=1:length(K_num)
		fprintf('++ K = %d for layer profile ...\n',K_num(K_ind))
		D = zeros(length(index),K_num(K_ind));
		[Km_cr(:,K_ind),~,~,D] = kmeans(dset_fit,K_num(K_ind),'MaxIter',500,'Distance','correlation','OnlinePhase','on');

		Km=Km_cr(:,K_ind);
		vnum = zeros(K_num(K_ind),1);
		for j=1:K_num(K_ind)
			vnum(j)=sum(Km==j);
		end
		[vseq,iseq] = sort(vnum);
		Kmsort=zeros(size(Km));
		for j=1:K_num(K_ind)
			Kmsort(find(Km==j))=iseq(j);
		end
		% Km_cr(:,K_ind)=Kmsort;

		% make sure that k1 corresponds to peak connectivity in superficial layers
		% while k2 corresponds to peak connectivity in middle-deep layers

		% prf_mid=zeros(K_num(K_ind),1);
		prf_sup=zeros(K_num(K_ind),1);
		% prf_dep=zeros(K_num(K_ind),1);
		for pc=1:K_num(K_ind)
			prf=abs(mean(dset_fit(Kmsort==pc,:)));
			% prf_mid(pc)=mean(prf(9:10));
			prf_sup(pc)=mean(prf(1:3));
			% prf_dep(pc)=mean(prf(16:18));
		end
		% [~,midmax]=max(prf_mid);
		[~,supmax]=max(prf_sup);
		% [~,depmax]=max(prf_dep);
		[~,supmin]=min(prf_sup);

		Kmsort1=zeros(size(Kmsort));
		if K_num(K_ind)==2
			Kmsort1(Kmsort==supmax)=1;
			Kmsort1(Kmsort==supmin)=2;
			Km_cr(:,K_ind)=Kmsort1;
		elseif K_num(K_ind)==3
			Kmsort1(Kmsort==supmax)=1;
			Kmsort1(Kmsort==supmin)=2;
			Kmsort1(Kmsort==(6-supmax-supmin))=3;
			Km_cr(:,K_ind)=Kmsort1;
		end

		% corrcoef for each cluster pattern
		r_fit = zeros(length(dset_fit),K_num(K_ind));
		z_fit = zeros(length(dset_fit),K_num(K_ind));


		% plot the profile for each cluster
		color_list = hsv(4);
		color_list = [0 0 1; 1 0 0; 0 1 0];
		p=zeros(4,0);
		figure;
		for pc=1:K_num(K_ind)
			prf=mean(dset_fit(Km_cr(:,K_ind)==pc,:));
			hold on;
			p(pc) = plot(layer,prf,'-','Color',color_list(pc,:),'LineWidth',2);
	
			r_fit(:,pc) = corr(dset_fit',prf');			
		end
		ylabel('Correlation (a.u.)','Fontsize',17,'FontWeight','normal');
		xlabel('Depth','Fontsize',17,'FontWeight','normal');
		% legend(p,'k1', 'k2','k3','k4','Location','northeast');
		box off
		whitebg('white');
		set(gcf,'color',[1 1 1])
		set(gca,'linewidth',2,'fontsize',17,'FontWeight','normal','Xcolor',[0 0 0],'Ycolor',[0 0 0])
		% title(extractBetween(subj_list(subj_ind).name,'hubpos.','sub_d_bold'),'fontsize',14,'FontWeight','normal','interpreter','none');
		fig_name=['K' num2str(K_num(K_ind)) extractBefore(dset_file,'.1D.dset') '.png'];
		export_fig(fig_name,'-r300');

	end

	outputData = zeros(length(dset),length(K_num));
	outputData(index,:) = Km_cr;

	outputNm = ['K2.' dset_file];
	dlmwrite(outputNm,outputData(:,1),'delimiter','\n');


end
