{
    Copyright (c) 1998-2002 by Florian Klaempfl

    Common x86 support for call nodes

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

 ****************************************************************************
}
unit nx86cal;

{$i fpcdefs.inc}

interface

{ $define AnsiStrRef}

    uses
      symdef,
      cgutils,
      ncgcal,parabase;

    type

       { tx86callnode }

       tx86callnode = class(tcgcallnode)
        protected
         procedure do_release_unused_return_value;override;
         procedure set_result_location(realresdef: tstoreddef);override;
         function can_call_ref(var ref: treference):boolean;override;
         function do_call_ref(ref: treference): tcgpara;override;
       end;


implementation

    uses
      globtype,cgobj,
      cgbase,cpubase,cgx86,cga,aasmdata,aasmcpu,
      hlcgobj;


{*****************************************************************************
                             TX86CALLNODE
*****************************************************************************}

    procedure tx86callnode.do_release_unused_return_value;
      begin
        case location.loc of
          LOC_FPUREGISTER :
             begin
               { release FPU stack }
               emit_reg(A_FSTP,S_NO,NR_FPU_RESULT_REG);
               tcgx86(cg).dec_fpu_stack;
             end
          else
            inherited do_release_unused_return_value;
        end;
      end;


  procedure tx86callnode.set_result_location(realresdef: tstoreddef);
    begin
      if (retloc.location^.loc=LOC_FPUREGISTER) then
        begin
          tcgx86(cg).inc_fpu_stack;
          location_reset(location,LOC_FPUREGISTER,retloc.location^.size);
          location.register:=retloc.location^.register;
        end
      else
        inherited set_result_location(realresdef);
    end;


  function tx86callnode.can_call_ref(var ref: treference): boolean;
    const
{$if defined(i386)}
      save_all_regs=[pocall_far16,pocall_oldfpccall];
{$else}
      save_all_regs=[];
{$endif}
    begin
      tcgx86(cg).make_simple_ref(current_asmdata.CurrAsmList,ref);
      { do not use a ref. for calling conventions which allocate all registers, the reg. allocator cannot handle this, see
        also issue #28639, I were not able to create a simple example though to cause the resulting endless spilling }
      result:=((getsupreg(ref.base)<first_int_imreg) and (getsupreg(ref.index)<first_int_imreg)) or
              not(procdefinition.proccalloption in save_all_regs);
    end;


  function tx86callnode.do_call_ref(ref: treference): tcgpara;
    begin
      current_asmdata.CurrAsmList.concat(taicpu.op_ref(A_CALL,S_NO,ref));
      result:=hlcg.get_call_result_cgpara(procdefinition,typedef)
    end;

end.
